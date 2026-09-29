import { mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

import { afterEach, describe, expect, it, vi } from 'vitest';

import { MEDIA_POLICY } from '../../../libs/media/src/domain/media-policy.js';
import { SupabaseMediaStorageService } from '../../../libs/media/src/infrastructure/supabase/supabase-media-storage.service.js';

function storageClient() {
  const bucket = {
    createSignedUploadUrl: vi.fn(),
    info: vi.fn(),
    download: vi.fn(),
    upload: vi.fn(),
    remove: vi.fn(),
  };
  const from = vi.fn(() => bucket);
  return { client: { storage: { from } }, from, bucket };
}

describe('SupabaseMediaStorageService', () => {
  const workspaces: string[] = [];

  afterEach(async () => {
    await Promise.all(workspaces.splice(0).map((path) => rm(path, { force: true, recursive: true })));
  });

  it('creates a non-upserting token for the exact staging path without returning its signed URL', async () => {
    const { client, from, bucket } = storageClient();
    bucket.createSignedUploadUrl.mockResolvedValue({
      data: {
        path: 'user/post/media/source.jpg',
        token: 'temporary-upload-token',
        signedUrl: 'https://storage.example/upload?token=temporary-upload-token',
      },
      error: null,
    });
    const storage = new SupabaseMediaStorageService(client);

    await expect(storage.createSignedUpload('user/post/media/source.jpg')).resolves.toEqual({
      path: 'user/post/media/source.jpg',
      token: 'temporary-upload-token',
    });
    expect(from).toHaveBeenCalledWith('post-media-staging');
    expect(bucket.createSignedUploadUrl).toHaveBeenCalledWith(
      'user/post/media/source.jpg',
      { upsert: false },
    );
  });

  it('redacts signed credentials and provider error bodies from failures', async () => {
    const { client, bucket } = storageClient();
    bucket.createSignedUploadUrl.mockResolvedValue({
      data: null,
      error: { message: 'rejected token=provider-secret' },
    });
    const storage = new SupabaseMediaStorageService(client);

    const error = await storage.createSignedUpload('safe/source.jpg').catch((caught: unknown) => caught);

    expect(String(error)).toContain('create_signed_upload_failed');
    expect(String(error)).not.toContain('provider-secret');
    expect(String(error)).not.toContain('safe/source.jpg');
  });

  it('returns exact staging metadata and treats a missing object as absent', async () => {
    const { client, from, bucket } = storageClient();
    bucket.info
      .mockResolvedValueOnce({
        data: {
          id: 'object-id',
          version: 'version-id',
          name: 'user/post/media/source.jpg',
          bucketId: 'post-media-staging',
          createdAt: '2026-09-29T00:00:00.000Z',
          size: 321_456,
          contentType: 'image/jpeg',
        },
        error: null,
      })
      .mockResolvedValueOnce({
        data: null,
        error: { status: 404, message: 'Object not found' },
      });
    const storage = new SupabaseMediaStorageService(client);

    await expect(storage.headStaging('user/post/media/source.jpg')).resolves.toEqual({
      bytes: 321_456,
      contentType: 'image/jpeg',
    });
    await expect(storage.headStaging('user/post/media/missing.jpg')).resolves.toBeNull();
    expect(from).toHaveBeenNthCalledWith(1, 'post-media-staging');
    expect(from).toHaveBeenNthCalledWith(2, 'post-media-staging');
    expect(bucket.info).toHaveBeenNthCalledWith(1, 'user/post/media/source.jpg');
    expect(bucket.info).toHaveBeenNthCalledWith(2, 'user/post/media/missing.jpg');
  });

  it('downloads staging bytes to the requested scratch destination', async () => {
    const workspace = await mkdtemp(join(tmpdir(), 'matchday-storage-test-'));
    workspaces.push(workspace);
    const destination = join(workspace, 'source.jpg');
    const { client, from, bucket } = storageClient();
    bucket.download.mockResolvedValue({
      data: new Blob([Uint8Array.from([0xff, 0xd8, 0xff, 0xd9])], { type: 'image/jpeg' }),
      error: null,
    });
    const storage = new SupabaseMediaStorageService(client);

    await storage.downloadStaging('user/post/media/source.jpg', destination);

    expect(await readFile(destination)).toEqual(Buffer.from([0xff, 0xd8, 0xff, 0xd9]));
    expect(from).toHaveBeenCalledWith('post-media-staging');
    expect(bucket.download).toHaveBeenCalledWith('user/post/media/source.jpg');
  });

  it('uploads immutable WebP variants only to the server-selected final bucket', async () => {
    const workspace = await mkdtemp(join(tmpdir(), 'matchday-storage-test-'));
    workspaces.push(workspace);
    const source = join(workspace, '360.webp');
    await writeFile(source, Buffer.from([1, 2, 3]));
    const { client, from, bucket } = storageClient();
    bucket.upload.mockResolvedValue({ data: { path: 'final/360.webp' }, error: null });
    const storage = new SupabaseMediaStorageService(client);

    await storage.uploadVariant('user/post/media/v1/360.webp', source);

    expect(from).toHaveBeenCalledWith('post-media');
    expect(bucket.upload).toHaveBeenCalledWith(
      'user/post/media/v1/360.webp',
      Buffer.from([1, 2, 3]),
      { cacheControl: '31536000', contentType: 'image/webp', upsert: false },
    );
  });

  it('deletes the exact staging object and exposes typed server policy', async () => {
    const { client, from, bucket } = storageClient();
    bucket.remove.mockResolvedValue({ data: [], error: null });
    const storage = new SupabaseMediaStorageService(client);

    await storage.deleteStaging('user/post/media/source.jpg');

    expect(from).toHaveBeenCalledWith('post-media-staging');
    expect(bucket.remove).toHaveBeenCalledWith(['user/post/media/source.jpg']);
    expect(MEDIA_POLICY).toMatchObject({
      stagingBucket: 'post-media-staging',
      finalBucket: 'post-media',
      source: { maxBytes: 15_728_640, mimeType: 'image/jpeg', maxLongEdge: 2048 },
    });
  });
});
