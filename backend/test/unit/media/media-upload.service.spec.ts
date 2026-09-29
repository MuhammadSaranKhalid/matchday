import { describe, expect, it, vi } from 'vitest';

import { MediaUploadService } from '../../../libs/modules/media/src/application/media-upload.service.js';
import type { MediaObjectStorage } from '../../../libs/modules/media/src/application/ports/media-object-storage.js';

describe('MediaUploadService', () => {
  it('delegates createUpload to the underlying storage', async () => {
    const storage: MediaObjectStorage = {
      createSignedUpload: vi.fn(async (path: string) => ({
        path,
        token: 'signed-token-123',
      })),
      headStaging: vi.fn(),
      downloadStaging: vi.fn(),
      uploadVariant: vi.fn(),
      deleteStaging: vi.fn(),
    };
    const service = new MediaUploadService(storage);

    const result = await service.createUpload('staging/path/photo.jpg');

    expect(result).toEqual({
      path: 'staging/path/photo.jpg',
      token: 'signed-token-123',
    });
    expect(storage.createSignedUpload).toHaveBeenCalledWith('staging/path/photo.jpg');
  });

  describe('verifyUpload', () => {
    it('returns missing when object is not found in staging', async () => {
      const storage: MediaObjectStorage = {
        createSignedUpload: vi.fn(),
        headStaging: vi.fn().mockResolvedValue(null),
        downloadStaging: vi.fn(),
        uploadVariant: vi.fn(),
        deleteStaging: vi.fn(),
      };
      const service = new MediaUploadService(storage);

      const result = await service.verifyUpload('staging/missing.jpg');

      expect(result).toEqual({ status: 'missing' });
    });

    it('returns too_large when bytes exceed MEDIA_POLICY max', async () => {
      const storage: MediaObjectStorage = {
        createSignedUpload: vi.fn(),
        headStaging: vi.fn().mockResolvedValue({
          bytes: 15_728_641,
          contentType: 'image/jpeg',
        }),
        downloadStaging: vi.fn(),
        uploadVariant: vi.fn(),
        deleteStaging: vi.fn(),
      };
      const service = new MediaUploadService(storage);

      const result = await service.verifyUpload('staging/large.jpg');

      expect(result).toEqual({ status: 'too_large' });
    });

    it('returns invalid_type when contentType is not image/jpeg', async () => {
      const storage: MediaObjectStorage = {
        createSignedUpload: vi.fn(),
        headStaging: vi.fn().mockResolvedValue({
          bytes: 100_000,
          contentType: 'image/png',
        }),
        downloadStaging: vi.fn(),
        uploadVariant: vi.fn(),
        deleteStaging: vi.fn(),
      };
      const service = new MediaUploadService(storage);

      const result = await service.verifyUpload('staging/not-jpeg.png');

      expect(result).toEqual({ status: 'invalid_type' });
    });

    it('returns valid with metadata when upload satisfies policy', async () => {
      const storage: MediaObjectStorage = {
        createSignedUpload: vi.fn(),
        headStaging: vi.fn().mockResolvedValue({
          bytes: 500_000,
          contentType: 'image/jpeg',
        }),
        downloadStaging: vi.fn(),
        uploadVariant: vi.fn(),
        deleteStaging: vi.fn(),
      };
      const service = new MediaUploadService(storage);

      const result = await service.verifyUpload('staging/valid.jpg');

      expect(result).toEqual({
        status: 'valid',
        bytes: 500_000,
        contentType: 'image/jpeg',
      });
    });
  });
});
