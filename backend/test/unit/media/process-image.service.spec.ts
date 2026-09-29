import { describe, expect, it, vi } from 'vitest';

import {
  PermanentMediaProcessingError,
  ProcessImageService,
} from '../../../libs/media/src/application/process-image.service.js';
import { PermanentImageError } from '../../../libs/media/src/application/ports/image-transformer.js';

const media = {
  mediaId: '40000000-0000-4000-8000-000000000001',
  postId: '30000000-0000-4000-8000-000000000001',
  stagingPath: 'user/post/media/source.jpg',
  finalPrefix: 'user/post/media/v1',
  pipelineVersion: 1,
  attempt: 1,
};

function fixture() {
  const events: string[] = [];
  const repository = {
    claim: vi.fn(async () => ({ claimed: true, status: 'processing', media })),
    releaseForRetry: vi.fn(async () => { events.push('release'); }),
    markFailed: vi.fn(async () => { events.push('failed'); }),
    markReady: vi.fn(async () => { events.push('ready'); }),
  };
  const storage = {
    createSignedUpload: vi.fn(), headStaging: vi.fn(),
    downloadStaging: vi.fn(async () => { events.push('download'); }),
    uploadVariant: vi.fn(async () => { events.push('upload'); }),
    deleteStaging: vi.fn(async () => { events.push('delete'); }),
  };
  const transformer = { transform: vi.fn(async () => ({
    sourceWidth: 100, sourceHeight: 80, displayWidth: 100, displayHeight: 80,
    blurhash: 'hash',
    variants: [{ name: '360.webp' as const, path: '/tmp/360.webp', width: 100,
      height: 80, bytes: 20, mimeType: 'image/webp' as const }],
  })) };
  const scratch = { use: vi.fn(async (work: (path: string) => Promise<void>) => {
    try { await work('/tmp/job'); } finally { events.push('cleanup'); }
  }) };
  return { service: new ProcessImageService(repository, storage, transformer, scratch),
    repository, storage, transformer, events };
}

describe('ProcessImageService', () => {
  it('is a no-op when the durable row cannot be claimed', async () => {
    const value = fixture();
    value.repository.claim.mockResolvedValueOnce({ claimed: false, status: 'ready' });
    await value.service.execute(media.mediaId, 1);
    expect(value.storage.downloadStaging).not.toHaveBeenCalled();
  });

  it('uploads immutable variants before the ready commit, then deletes staging', async () => {
    const value = fixture();
    await value.service.execute(media.mediaId, 1);
    expect(value.storage.uploadVariant).toHaveBeenCalledWith(
      'user/post/media/v1/360.webp', '/tmp/360.webp',
    );
    expect(value.events).toEqual(['download', 'upload', 'ready', 'delete', 'cleanup']);
  });

  it('releases transient failures and always cleans scratch', async () => {
    const value = fixture();
    value.transformer.transform.mockRejectedValueOnce(new Error('storage_timeout'));
    await expect(value.service.execute(media.mediaId, 1)).rejects.toThrow('storage_timeout');
    expect(value.events).toEqual(['download', 'cleanup', 'release']);
  });

  it('persists permanent failures before surfacing an unrecoverable error', async () => {
    const value = fixture();
    value.transformer.transform.mockRejectedValueOnce(new PermanentImageError('invalid_image'));
    await expect(value.service.execute(media.mediaId, 1))
      .rejects.toBeInstanceOf(PermanentMediaProcessingError);
    expect(value.events).toEqual(['download', 'cleanup', 'failed']);
  });
});
