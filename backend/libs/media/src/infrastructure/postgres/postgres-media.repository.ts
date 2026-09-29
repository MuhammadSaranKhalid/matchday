import type { DatabaseExecutorService } from '../../../../platform/src/database/database-executor.service.js';
import type { QueryExecutor } from '../../../../platform/src/database/database.types.js';
import type { TransformedImage } from '../../application/ports/image-transformer.js';
import type {
  ClaimedMedia,
  MediaClaimResult,
  MediaRepository,
} from '../../application/ports/media-repository.js';

@Injectable()
export class PostgresMediaRepository implements MediaRepository {
  constructor(private readonly database: DatabaseExecutorService) {}

  claim(mediaId: string): Promise<MediaClaimResult> {
    return this.database.withSystemTransaction(async (tx) => {
      const value = await jsonFunction(tx, 'private.claim_post_media_for_processing($1)', [mediaId]);
      const claimed = value['claimed'] === true;
      return Object.freeze({
        claimed,
        status: String(value['status'] ?? 'missing'),
        ...(claimed ? { media: parseClaim(value) } : {}),
      });
    });
  }

  releaseForRetry(mediaId: string, error: string): Promise<void> {
    return this.callBoolean('private.release_post_media_for_retry($1, $2)', [mediaId, error]);
  }

  markFailed(mediaId: string, error: string): Promise<void> {
    return this.callBoolean('private.mark_post_media_failed($1, $2)', [mediaId, error]);
  }

  markReady(mediaId: string, image: TransformedImage): Promise<void> {
    const variants = Object.fromEntries(image.variants.map((variant) => [
      Number.parseInt(variant.name, 10),
      {
        path: variant.path,
        width: variant.width,
        height: variant.height,
        bytes: variant.bytes,
        mime: variant.mimeType,
      },
    ]));
    return this.database.withSystemTransaction(async (tx) => {
      await tx.query(
        'select private.mark_post_media_ready($1, $2, $3, $4, $5, $6, $7::jsonb)',
        [mediaId, image.sourceWidth, image.sourceHeight, image.displayWidth,
          image.displayHeight, image.blurhash, JSON.stringify(variants)],
      );
    });
  }

  private async callBoolean(sql: string, values: readonly unknown[]): Promise<void> {
    await this.database.withSystemTransaction(async (tx) => {
      await tx.query(`select ${sql}`, values);
    });
  }
}

async function jsonFunction(
  tx: QueryExecutor,
  expression: string,
  values: readonly unknown[],
): Promise<Record<string, unknown>> {
  const result = await tx.query<{ value: Record<string, unknown> }>(
    `select ${expression} as value`,
    values,
  );
  return result.rows[0]?.value ?? {};
}

function parseClaim(value: Record<string, unknown>): ClaimedMedia {
  return Object.freeze({
    mediaId: String(value['media_id']),
    postId: String(value['post_id']),
    stagingPath: String(value['staging_path']),
    finalPrefix: String(value['final_prefix']),
    pipelineVersion: Number(value['pipeline_version']),
    attempt: Number(value['attempt']),
  });
}
import { Injectable } from '@nestjs/common';
