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
  return { repository, mediaUpload };
}

describe('PublishPostService', () => {
  it('verifies every expected object and atomically records uploads without direct queue work', async () => {
    const { repository, mediaUpload } = dependencies();
    const service = new PublishPostService(repository, mediaUpload);

    await expect(service.execute(principal, postId)).resolves.toEqual({ status: 'processing' });

    expect(mediaUpload.verifyUpload).toHaveBeenCalledTimes(2);
    expect(repository.markUploaded).toHaveBeenCalledWith(principal, postId, [
      { mediaId: media[0]!.mediaId, bytes: 600_000, contentType: 'image/jpeg' },
      { mediaId: media[1]!.mediaId, bytes: 600_000, contentType: 'image/jpeg' },
    ]);
  });

  it.each([
    [{ status: 'missing' as const }, 'POST_MEDIA_MISSING'],
    [{ status: 'too_large' as const }, 'POST_MEDIA_TOO_LARGE'],
    [{ status: 'invalid_type' as const }, 'POST_MEDIA_INVALID_TYPE'],
  ])('rejects invalid staging verification %o', async (verification, code) => {
    const { repository, mediaUpload } = dependencies();
    mediaUpload.verifyUpload.mockResolvedValueOnce(verification);
    const service = new PublishPostService(repository, mediaUpload);

    await expect(service.execute(principal, postId)).rejects.toMatchObject({ code, status: 400 });
    expect(repository.markUploaded).not.toHaveBeenCalled();
  });

  it('publishes a text-only draft without Storage work', async () => {
    const { repository, mediaUpload } = dependencies({
      findOwnedPost: vi.fn().mockResolvedValue({ postId, status: 'draft', media: [] }),
    });
    const service = new PublishPostService(repository, mediaUpload);

    await expect(service.execute(principal, postId)).resolves.toEqual({ status: 'published' });
    expect(repository.publishTextOnly).toHaveBeenCalledWith(principal, postId);
    expect(mediaUpload.verifyUpload).not.toHaveBeenCalled();
    expect(repository.markUploaded).not.toHaveBeenCalled();
  });

  it('keeps repeated publish idempotent and avoids duplicate markUploaded when all media is already uploaded', async () => {
    const uploaded = media.map((item) => ({ ...item, status: 'uploaded' as const }));
    const { repository, mediaUpload } = dependencies({
      findOwnedPost: vi.fn().mockResolvedValue({ postId, status: 'processing', media: uploaded }),
    });
    const service = new PublishPostService(repository, mediaUpload);

    await expect(service.execute(principal, postId)).resolves.toEqual({ status: 'processing' });
    expect(mediaUpload.verifyUpload).not.toHaveBeenCalled();
    expect(repository.markUploaded).not.toHaveBeenCalled();
  });

  it('rejects an unknown or foreign draft and maps owner-scoped durable status', async () => {
    const { repository, mediaUpload } = dependencies({
      findOwnedPost: vi.fn().mockResolvedValue(null),
    });
    const service = new PublishPostService(repository, mediaUpload);

    await expect(service.execute(principal, postId)).rejects.toMatchObject({
      code: 'POST_NOT_FOUND',
      status: 404,
    });
    await expect(service.status(principal, postId)).resolves.toEqual({ status: 'processing' });
  });
});
