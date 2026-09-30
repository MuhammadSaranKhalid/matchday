import { readFile, writeFile } from 'node:fs/promises';

import type { SupabaseClient } from '@supabase/supabase-js';

import type {
  MediaProcessingStorage,
  MediaUploadStorage,
  SignedMediaUpload,
  StagingObjectMetadata,
} from '../../application/ports/media-object-storage.js';
import { MEDIA_POLICY } from '../../domain/media-policy.js';

type StorageClient = Pick<SupabaseClient, 'storage'>;

export interface SupabaseMediaStorageConfig {
  readonly stagingBucket: string;
  readonly finalBucket: string;
  readonly cacheControl: string;
}

export const DEFAULT_MEDIA_STORAGE_CONFIG: SupabaseMediaStorageConfig = Object.freeze({
  stagingBucket: 'post-media-staging',
  finalBucket: 'post-media',
  cacheControl: '31536000',
});

export class SupabaseMediaStorageService
  implements MediaUploadStorage, MediaProcessingStorage
{
  private readonly config: SupabaseMediaStorageConfig;

  constructor(
    private readonly client: StorageClient,
    config: Partial<SupabaseMediaStorageConfig> = {},
  ) {
    this.config = { ...DEFAULT_MEDIA_STORAGE_CONFIG, ...config };
  }

  async createSignedUpload(path: string): Promise<SignedMediaUpload> {
    const { data, error } = await this.client.storage
      .from(this.config.stagingBucket)
      .createSignedUploadUrl(path, { upsert: false });

    if (error || data === null) throw storageFailure('create_signed_upload_failed');
    return Object.freeze({ path: data.path, token: data.token });
  }

  async headStaging(path: string): Promise<StagingObjectMetadata | null> {
    const { data, error } = await this.client.storage
      .from(this.config.stagingBucket)
      .info(path);

    if (error) {
      if (isMissingObject(error)) return null;
      throw storageFailure('head_staging_failed');
    }
    if (data.size === undefined || data.contentType === undefined) {
      throw storageFailure('invalid_staging_metadata');
    }

    return Object.freeze({ bytes: data.size, contentType: data.contentType });
  }

  async downloadStaging(path: string, destination: string): Promise<void> {
    const { data, error } = await this.client.storage
      .from(this.config.stagingBucket)
      .download(path);

    if (error || data === null) throw storageFailure('download_staging_failed');
    await writeFile(destination, Buffer.from(await data.arrayBuffer()));
  }

  async uploadVariant(path: string, source: string): Promise<void> {
    const bytes = await readFile(source);
    const { error } = await this.client.storage
      .from(this.config.finalBucket)
      .upload(path, bytes, {
        cacheControl: this.config.cacheControl,
        contentType: MEDIA_POLICY.variant.mimeType,
        upsert: false,
      });

    if (error && !isAlreadyStored(error)) throw storageFailure('upload_variant_failed');
  }

  async deleteStaging(path: string): Promise<void> {
    const { error } = await this.client.storage
      .from(this.config.stagingBucket)
      .remove([path]);
    if (error) throw storageFailure('delete_staging_failed');
  }
}

function isMissingObject(error: unknown): boolean {
  if (typeof error !== 'object' || error === null) return false;
  const candidate = error as { status?: number; statusCode?: string };
  return candidate.status === 404 || candidate.statusCode === '404';
}

function isAlreadyStored(error: unknown): boolean {
  if (typeof error !== 'object' || error === null) return false;
  const candidate = error as { status?: number; statusCode?: string; message?: string };
  return candidate.status === 409 || candidate.statusCode === '409' ||
    candidate.message?.toLowerCase().includes('already exists') === true;
}

function storageFailure(code: string): Error {
  return new Error(code);
}
