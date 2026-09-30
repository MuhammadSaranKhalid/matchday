export const MEDIA_UPLOAD_STORAGE = Symbol('MEDIA_UPLOAD_STORAGE');
export const MEDIA_PROCESSING_STORAGE = Symbol('MEDIA_PROCESSING_STORAGE');

export interface SignedMediaUpload {
  readonly path: string;
  readonly token: string;
}

export interface StagingObjectMetadata {
  readonly bytes: number;
  readonly contentType: string;
}

export interface MediaUploadStorage {
  createSignedUpload(path: string): Promise<SignedMediaUpload>;
  headStaging(path: string): Promise<StagingObjectMetadata | null>;
}

export interface MediaProcessingStorage {
  downloadStaging(path: string, destination: string): Promise<void>;
  uploadVariant(path: string, source: string): Promise<void>;
  deleteStaging(path: string): Promise<void>;
}
