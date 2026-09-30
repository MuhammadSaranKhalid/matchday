import { describe, expect, it, vi } from 'vitest';

import type { AuthenticatedPrincipal } from '../../../libs/platform/src/auth/authenticated-principal.js';
import { PostgresPostCommandRepository } from '../../../libs/modules/posts/src/infrastructure/persistence/postgres-post-command.repository.js';

const principal: AuthenticatedPrincipal = {
  userId: '10000000-0000-4000-8000-000000000001',
  role: 'authenticated',
  appMetadata: {},
};
const postId = '20000000-0000-4000-8000-000000000001';
const mediaId = '30000000-0000-4000-8000-000000000001';

describe('PostgresPostCommandRepository.markUploaded', () => {
  it('transitions post_media rows to uploaded status within owner transaction', async () => {
    const executedQueries: Array<{ sql: string; values?: unknown[] }> = [];

    const tx = {
      query: vi.fn(async (sql: string, values?: unknown[]) => {
        executedQueries.push({ sql, values });
        if (sql.includes('from public.posts where post_id = $1 and created_by_user_id = $2')) {
          return { rowCount: 1, rows: [{ post_id: postId }] };
        }
        if (sql.includes('update public.post_media')) {
          return { rowCount: 1, rows: [] };
        }
        if (sql.includes("update public.posts set status = 'publishing'")) {
          return { rowCount: 1, rows: [] };
        }
        return { rowCount: 0, rows: [] };
      }),
    };

    const database = {
      withSystemTransaction: vi.fn(async (work: (t: typeof tx) => Promise<unknown>) => work(tx)),
    };

    const repository = new PostgresPostCommandRepository(database as never);

    await repository.markUploaded(principal, postId, [
      { mediaId, bytes: 500_000, contentType: 'image/jpeg' },
    ]);

    expect(database.withSystemTransaction).toHaveBeenCalledOnce();

    // Verify post_media update query
    const updateMedia = executedQueries.find((q) => q.sql.includes('update public.post_media'));
    expect(updateMedia).toBeDefined();
    expect(updateMedia!.sql).toContain("status = 'uploaded'");
    expect(updateMedia!.values).toEqual([mediaId, postId, 500_000, 'image/jpeg']);

    // Verify no outbox queries
    const outboxQuery = executedQueries.find((q) => q.sql.includes('media_processing_outbox'));
    expect(outboxQuery).toBeUndefined();
  });

  it('rejects with POST_MEDIA_STATE_CONFLICT if media row cannot be transitioned', async () => {
    const tx = {
      query: vi.fn(async (sql: string) => {
        if (sql.includes('from public.posts where post_id = $1 and created_by_user_id = $2')) {
          return { rowCount: 1, rows: [{ post_id: postId }] };
        }
        if (sql.includes('update public.post_media')) {
          return { rowCount: 0, rows: [] };
        }
        return { rowCount: 0, rows: [] };
      }),
    };

    const database = {
      withSystemTransaction: vi.fn(async (work: (t: typeof tx) => Promise<unknown>) => work(tx)),
    };

    const repository = new PostgresPostCommandRepository(database as never);

    await expect(
      repository.markUploaded(principal, postId, [
        { mediaId, bytes: 500_000, contentType: 'image/jpeg' },
      ]),
    ).rejects.toMatchObject({
      code: 'POST_MEDIA_STATE_CONFLICT',
      status: 409,
    });
  });

  it('rejects if caller is not the post owner', async () => {
    const tx = {
      query: vi.fn(async (sql: string) => {
        if (sql.includes('from public.posts where post_id = $1 and created_by_user_id = $2')) {
          return { rowCount: 0, rows: [] };
        }
        return { rowCount: 0, rows: [] };
      }),
    };

    const database = {
      withSystemTransaction: vi.fn(async (work: (t: typeof tx) => Promise<unknown>) => work(tx)),
    };

    const repository = new PostgresPostCommandRepository(database as never);

    await expect(
      repository.markUploaded(principal, postId, [
        { mediaId, bytes: 500_000, contentType: 'image/jpeg' },
      ]),
    ).rejects.toMatchObject({
      code: 'POST_NOT_FOUND',
      status: 404,
    });
  });
});
