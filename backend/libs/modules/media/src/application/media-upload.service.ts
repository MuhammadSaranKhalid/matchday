import { MEDIA_POLICY } from '../domain/media-policy.js';
import type {
  MediaObjectStorage,
  SignedMediaUpload,
} from './ports/media-object-storage.js';

export type StagedMediaVerification =
  | {
      readonly status: 'valid';
      readonly bytes: number;
      readonly contentType: typeof MEDIA_POLICY.source.mimeType;
    }
  | { readonly status: 'missing' }
  | { readonly status: 'too_large' }
  | { readonly status: 'invalid_type' };

export class MediaUploadService {
  constructor(private readonly storage: MediaObjectStorage) {}

  createUpload(path: string): Promise<SignedMediaUpload> {
    return this.storage.createSignedUpload(path);
  }

  async verifyUpload(path: string): Promise<StagedMediaVerification> {
    const metadata = await this.storage.headStaging(path);
    if (metadata === null) {
      return Object.freeze({ status: 'missing' });
    }
    if (metadata.bytes > MEDIA_POLICY.source.maxBytes) {
      return Object.freeze({ status: 'too_large' });
    }
    if (metadata.contentType !== MEDIA_POLICY.source.mimeType) {
      return Object.freeze({ status: 'invalid_type' });
    }
    return Object.freeze({
      status: 'valid',
      bytes: metadata.bytes,
      contentType: MEDIA_POLICY.source.mimeType,
    });
  }
}
