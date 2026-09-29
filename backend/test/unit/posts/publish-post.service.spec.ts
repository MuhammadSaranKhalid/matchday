import { describe, expect, it, vi } from 'vitest';

import type { AuthenticatedPrincipal } from '../../../libs/platform/src/auth/authenticated-principal.js';
import { PublishPostService } from '../../../libs/modules/posts/src/application/publish-post.service.js';

const principal: AuthenticatedPrincipal = {
  userId: '10000000-0000-4000-8000-000000000001',
  role: 'authenticated',
  appMetadata: {},
};
const postId = '30000000-0000-4000-8000-000000000001';
const media = [
  {
    mediaId: '40000000-0000-4000-8000-000000000001',
    position: 0,
    status: 'pending_upload' as const,
    stagingPath: 'user/post/first/source.jpg',
  },
  {
    mediaId: '40000000-0000-4000-8000-000000000002',
    position: 1,
    status: 'pending_upload' as const,
    stagingPath: 'user/post/second/source.jpg',
  },
];

function dependencies(overrides: Record<string, unknown> = {}) {
  const repository = {
    findOwnedPost: vi.fn().mockResolvedValue({ postId, status: 'draft', media }),
    markUploaded: vi.fn().mockResolvedValue(undefined),
    publishTextOnly: vi.fn().mockResolvedValue(undefined),
    getOwnedStatus: vi.fn().mockResolvedValue('processing'),
    ...overrides,
  };
  const mediaUpload = {
    verifyUpload: vi.fn().mockResolvedValue({
      status: 'valid' as const,
      bytes: 600_000,
      contentType: 'image/jpeg' as const,
    }),
  };
  const scheduler = { scheduleProcessing: vi.fn().mockResolvedValue(undefined) };
  return { repository, mediaUpload, scheduler };
}

describe('PublishPostService', () => {
  it('verifies every expected object, records uploads, and enqueues deterministic image work', async () => {
    const { repository, mediaUpload, scheduler } = dependencies();
    const service = new PublishPostService(repository, mediaUpload, scheduler);

    await expect(service.execute(principal, postId)).resolves.toEqual({ status: 'processing' });

    expect(mediaUpload.verifyUpload).toHaveBeenCalledTimes(2);
    expect(repository.markUploaded).toHaveBeenCalledWith(principal, postId, [
      { mediaId: media[0]!.mediaId, bytes: 600_000, contentType: 'image/jpeg' },
      { mediaId: media[1]!.mediaId, bytes: 600_000, contentType: 'image/jpeg' },
    ]);
    expect(scheduler.scheduleProcessing).toHaveBeenNthCalledWith(1, media[0]!.mediaId);
    expect(scheduler.scheduleProcessing).toHaveBeenNthCalledWith(2, media[1]!.mediaId);
  });

  it.each([
    [{ status: 'missing' as const }, 'POST_MEDIA_MISSING'],
    [{ status: 'too_large' as const }, 'POST_MEDIA_TOO_LARGE'],
    [{ status: 'invalid_type' as const }, 'POST_MEDIA_INVALID_TYPE'],
  ])('rejects invalid staging verification %o', async (verification, code) => {
    const { repository, mediaUpload, scheduler } = dependencies();
    mediaUpload.verifyUpload.mockResolvedValueOnce(verification);
    const service = new PublishPostService(repository, mediaUpload, scheduler);

    await expect(service.execute(principal, postId)).rejects.toMatchObject({ code, status: 400 });
    expect(repository.markUploaded).not.toHaveBeenCalled();
    expect(scheduler.scheduleProcessing).not.toHaveBeenCalled();
  });

  it('surfaces a partial enqueue failure so the same publish command can retry', async () => {
    const { repository, mediaUpload, scheduler } = dependencies();
    scheduler.scheduleProcessing
      .mockResolvedValueOnce(undefined)
      .mockRejectedValueOnce(new Error('redis unavailable'));
    const service = new PublishPostService(repository, mediaUpload, scheduler);

    await expect(service.execute(principal, postId)).rejects.toThrow('redis unavailable');
    expect(repository.markUploaded).toHaveBeenCalledOnce();
    expect(scheduler.scheduleProcessing).toHaveBeenCalledTimes(2);
  });

  it('publishes a text-only draft without Storage or queue work', async () => {
    const { repository, mediaUpload, scheduler } = dependencies({
      findOwnedPost: vi.fn().mockResolvedValue({ postId, status: 'draft', media: [] }),
    });
    const service = new PublishPostService(repository, mediaUpload, scheduler);

    await expect(service.execute(principal, postId)).resolves.toEqual({ status: 'published' });
    expect(repository.publishTextOnly).toHaveBeenCalledWith(principal, postId);
    expect(mediaUpload.verifyUpload).not.toHaveBeenCalled();
    expect(scheduler.scheduleProcessing).not.toHaveBeenCalled();
  });

  it('keeps repeated publish idempotent while ensuring uploaded work is enqueued', async () => {
    const uploaded = media.map((item) => ({ ...item, status: 'uploaded' as const }));
    const { repository, mediaUpload, scheduler } = dependencies({
      findOwnedPost: vi.fn().mockResolvedValue({ postId, status: 'processing', media: uploaded }),
    });
    const service = new PublishPostService(repository, mediaUpload, scheduler);

    await expect(service.execute(principal, postId)).resolves.toEqual({ status: 'processing' });
    expect(mediaUpload.verifyUpload).not.toHaveBeenCalled();
    expect(repository.markUploaded).not.toHaveBeenCalled();
    expect(scheduler.scheduleProcessing).toHaveBeenCalledTimes(2);
  });

  it('rejects an unknown or foreign draft and maps owner-scoped durable status', async () => {
    const { repository, mediaUpload, scheduler } = dependencies({
      findOwnedPost: vi.fn().mockResolvedValue(null),
    });
    const service = new PublishPostService(repository, mediaUpload, scheduler);

    await expect(service.execute(principal, postId)).rejects.toMatchObject({
      code: 'POST_NOT_FOUND',
      status: 404,
    });
    await expect(service.status(principal, postId)).resolves.toEqual({ status: 'processing' });
  });
});
