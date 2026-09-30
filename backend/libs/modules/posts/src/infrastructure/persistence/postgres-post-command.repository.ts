import { Injectable } from '@nestjs/common';

import type { AuthenticatedPrincipal } from '../../../../../platform/src/auth/authenticated-principal.js';
import { DatabaseExecutorService } from '../../../../../platform/src/database/database-executor.service.js';
import { ApplicationError } from '../../../../../platform/src/errors/application-error.js';
import type {
  CreatePostCommand,
  OwnedPost,
  PostCommandRepository,
  PostProcessingStatus,
  ReservedPost,
  UploadedMediaMetadata,
} from '../../application/post-command.ports.js';

@Injectable()
export class PostgresPostCommandRepository implements PostCommandRepository {
  constructor(private readonly database: DatabaseExecutorService) {}

  reserveDraft(principal: AuthenticatedPrincipal, command: CreatePostCommand): Promise<ReservedPost> {
    return this.database.withSystemTransaction(async (tx) => {
      await setPrincipal(tx, principal);
      const existing = await tx.query<{ post_id: string }>(
        'select post_id from public.posts where created_by_user_id = $1 and idempotency_key = $2',
        [principal.userId, command.clientCommandId],
      );
      let postId = existing.rows[0]?.post_id;
      if (postId === undefined) {
        const authorization = await tx.query<{ allowed: boolean }>(
          'select public.can_publish_as($1::public.post_publisher_type, $2::uuid, $3::uuid) as allowed',
          [command.publisherType, command.publisherId, principal.userId],
        );
        if (authorization.rows[0]?.allowed !== true) {
          throw new ApplicationError('PERMISSION_DENIED', 'Publisher is not authorized', 403);
        }
        const created = await tx.query<{ post_id: string }>(
          `insert into public.posts
            (created_by_user_id, publisher_type, publisher_id, post_kind, text,
             expected_media_count, idempotency_key, status)
           values ($1, $2, $3, $4::public.post_kind, $5, $6, $7, 'publishing')
           returning post_id`,
          [
            principal.userId,
            command.publisherType,
            command.publisherId,
            command.postKind,
            command.text ?? null,
            command.media.length,
            command.clientCommandId,
          ],
        );
        postId = created.rows[0]!.post_id;
        for (const [position, item] of command.media.entries()) {
          const mediaId = crypto.randomUUID();
          await tx.query(
            `insert into public.post_media
              (media_id, post_id, position, staging_path, final_prefix, status,
               source_width, source_height, source_bytes, source_mime)
             values ($1, $2, $3, $4, $5, 'pending_upload', $6, $7, $8, $9)`,
            [
              mediaId,
              postId,
              position,
              `${principal.userId}/${postId}/${mediaId}/source.jpg`,
              `${principal.userId}/${postId}/${mediaId}/v1`,
              item.width,
              item.height,
              item.bytes,
              item.mimeType,
            ],
          );
        }
      }
      return loadReserved(tx, postId);
    });
  }

  findOwnedPost(principal: AuthenticatedPrincipal, postId: string): Promise<OwnedPost | null> {
    return this.database.withSystemTransaction(async (tx) => {
      const post = await tx.query<{ post_id: string; status: string }>(
        'select post_id, status::text from public.posts where post_id = $1 and created_by_user_id = $2',
        [postId, principal.userId],
      );
      if (post.rows[0] === undefined) return null;
      const media = await loadMedia(tx, postId);
      return { postId, status: mapPostState(post.rows[0].status), media };
    });
  }

  markUploaded(
    principal: AuthenticatedPrincipal,
    postId: string,
    media: readonly UploadedMediaMetadata[],
  ): Promise<void> {
    return this.database.withSystemTransaction(async (tx) => {
      await requireOwner(tx, principal.userId, postId);
      for (const item of media) {
        const result = await tx.query<{ generation: number }>(
          `update public.post_media
           set status = 'uploaded',
               source_bytes = $3,
               source_mime = $4,
               processing_generation = processing_generation + 1,
               updated_at = now()
           where media_id = $1 and post_id = $2 and status = 'pending_upload'
           returning processing_generation as generation`,
          [item.mediaId, postId, item.bytes, item.contentType],
        );
        if (result.rowCount !== 1) {
          throw new ApplicationError('POST_MEDIA_STATE_CONFLICT', 'Media state changed', 409);
        }
        const generation = result.rows[0]!.generation;
        await tx.query(
          `insert into private.media_processing_outbox (media_id, generation)
           values ($1, $2)`,
          [item.mediaId, generation],
        );
      }
      await tx.query(
        "update public.posts set status = 'publishing' where post_id = $1 and status = 'publishing'",
        [postId],
      );
    });
  }

  publishTextOnly(principal: AuthenticatedPrincipal, postId: string): Promise<void> {
    return this.database.withSystemTransaction(async (tx) => {
      await requireOwner(tx, principal.userId, postId);
      await tx.query(
        "update public.posts set status = 'active', published_at = coalesce(published_at, now()) where post_id = $1 and expected_media_count = 0 and status in ('publishing', 'active')",
        [postId],
      );
    });
  }

  getOwnedStatus(principal: AuthenticatedPrincipal, postId: string): Promise<PostProcessingStatus | null> {
    return this.database.withSystemTransaction(async (tx) => {
      const result = await tx.query<{ status: string; failed: boolean }>(
        `select p.status::text, exists (
           select 1 from public.post_media pm where pm.post_id = p.post_id and pm.status = 'failed'
         ) as failed
         from public.posts p where p.post_id = $1 and p.created_by_user_id = $2`,
        [postId, principal.userId],
      );
      const row = result.rows[0];
      if (row === undefined) return null;
      if (row.failed) return 'failed';
      return row.status === 'active' ? 'published' : 'processing';
    });
  }
}

type Executor = Parameters<Parameters<DatabaseExecutorService['withSystemTransaction']>[0]>[0];

async function setPrincipal(tx: Executor, principal: AuthenticatedPrincipal): Promise<void> {
  await tx.query("select set_config('request.jwt.claims', $1, true)", [
    JSON.stringify({ sub: principal.userId, role: principal.role, app_metadata: principal.appMetadata }),
  ]);
}

async function requireOwner(tx: Executor, userId: string, postId: string): Promise<void> {
  const result = await tx.query('select 1 from public.posts where post_id = $1 and created_by_user_id = $2 for update', [postId, userId]);
  if (result.rowCount !== 1) throw new ApplicationError('POST_NOT_FOUND', 'Post not found', 404);
}

async function loadReserved(tx: Executor, postId: string): Promise<ReservedPost> {
  const media = (await loadMedia(tx, postId)).map((item) => ({
    mediaId: item.mediaId,
    position: item.position,
    stagingPath: item.stagingPath,
  }));
  return { postId, status: 'draft', media };
}

async function loadMedia(tx: Executor, postId: string) {
  const result = await tx.query<{
    media_id: string; position: number; staging_path: string; status: OwnedPost['media'][number]['status'];
  }>(
    'select media_id, position, staging_path, status::text from public.post_media where post_id = $1 order by position',
    [postId],
  );
  return result.rows.map((row) => ({
    mediaId: row.media_id,
    position: row.position,
    stagingPath: row.staging_path,
    status: row.status,
  }));
}

function mapPostState(status: string): OwnedPost['status'] {
  if (status === 'draft') return 'draft';
  if (status === 'active') return 'published';
  if (status === 'failed') return 'failed';
  return 'processing';
}
