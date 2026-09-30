import { describe, expect, it, vi } from 'vitest';

import type { AuthenticatedPrincipal } from '@shared-kernel/identity/authenticated-principal.js';
import { CreatePostService } from '../../../libs/modules/posts/src/application/create-post.service.js';

const principal: AuthenticatedPrincipal = {
  userId: '10000000-0000-4000-8000-000000000001',
  role: 'authenticated',
  appMetadata: {},
};

const command = {
  clientCommandId: '20000000-0000-4000-8000-000000000001',
  publisherType: 'user' as const,
  publisherId: principal.userId,
  postKind: 'standard' as const,
  text: 'Matchday',
  media: [
    { width: 1200, height: 800, bytes: 500_000, mimeType: 'image/jpeg' as const },
    { width: 800, height: 1200, bytes: 600_000, mimeType: 'image/jpeg' as const },
  ],
};

const draft = {
  postId: '30000000-0000-4000-8000-000000000001',
  status: 'draft' as const,
  media: [
    {
      mediaId: '40000000-0000-4000-8000-000000000001',
      position: 0,
      stagingPath: 'user/post/first/source.jpg',
    },
    {
      mediaId: '40000000-0000-4000-8000-000000000002',
      position: 1,
      stagingPath: 'user/post/second/source.jpg',
    },
  ],
};

describe('CreatePostService', () => {
  it('preserves server-reserved media ordering and adds a token for each exact path', async () => {
    const repository = { reserveDraft: vi.fn().mockResolvedValue(draft) };
    const mediaUpload = {
      createUpload: vi.fn(async (path: string) => ({ path, token: `token-${path}` })),
    };
    const service = new CreatePostService(repository, mediaUpload);

    const result = await service.execute(principal, command);

    expect(result).toEqual({
      ...draft,
      media: [
        { ...draft.media[0], uploadToken: 'token-user/post/first/source.jpg' },
        { ...draft.media[1], uploadToken: 'token-user/post/second/source.jpg' },
      ],
    });
  });

  it('rejects five images before reserving database state', async () => {
    const repository = { reserveDraft: vi.fn() };
    const mediaUpload = { createUpload: vi.fn() };
    const service = new CreatePostService(repository, mediaUpload);

    await expect(service.execute(principal, {
      ...command,
      media: Array.from({ length: 5 }, () => command.media[0]!),
    })).rejects.toMatchObject({ code: 'POST_MEDIA_LIMIT_EXCEEDED', kind: 'validation' });
    expect(repository.reserveDraft).not.toHaveBeenCalled();
  });

  it('rejects an empty text-only command before reserving database state', async () => {
    const repository = { reserveDraft: vi.fn() };
    const mediaUpload = { createUpload: vi.fn() };
    const service = new CreatePostService(repository, mediaUpload);

    await expect(service.execute(principal, {
      ...command,
      text: '   ',
      media: [],
    })).rejects.toMatchObject({ code: 'POST_CONTENT_REQUIRED', kind: 'validation' });
    expect(repository.reserveDraft).not.toHaveBeenCalled();
  });

  it('reuses stable draft identities but issues fresh tokens on an idempotent retry', async () => {
    const repository = { reserveDraft: vi.fn().mockResolvedValue(draft) };
    let generation = 0;
    const mediaUpload = {
      createUpload: vi.fn(async (path: string) => ({
        path,
        token: `generation-${generation}-${path}`,
      })),
    };
    const service = new CreatePostService(repository, mediaUpload);

    generation = 1;
    const first = await service.execute(principal, command);
    generation = 2;
    const retry = await service.execute(principal, command);

    expect(retry.postId).toBe(first.postId);
    expect(retry.media.map((item) => item.mediaId)).toEqual(first.media.map((item) => item.mediaId));
    expect(retry.media.map((item) => item.stagingPath)).toEqual(first.media.map((item) => item.stagingPath));
    expect(retry.media.map((item) => item.uploadToken)).not.toEqual(
      first.media.map((item) => item.uploadToken),
    );
    expect(repository.reserveDraft).toHaveBeenCalledTimes(2);
  });

  it('can safely retry token generation without creating another draft identity', async () => {
    const repository = { reserveDraft: vi.fn().mockResolvedValue(draft) };
    const mediaUpload = {
      createUpload: vi.fn()
        .mockRejectedValueOnce(new Error('storage unavailable'))
        .mockImplementation(async (path: string) => ({ path, token: `fresh-${path}` })),
    };
    const service = new CreatePostService(repository, mediaUpload);

    await expect(service.execute(principal, command)).rejects.toThrow('storage unavailable');
    await expect(service.execute(principal, command)).resolves.toMatchObject({ postId: draft.postId });
    expect(repository.reserveDraft).toHaveBeenCalledTimes(2);
  });
});
