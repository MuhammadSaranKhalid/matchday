export const MEDIA_OBJECT_STORAGE = Symbol('MEDIA_OBJECT_STORAGE');

export interface SignedMediaUpload {
  readonly path: string;
  readonly token: string;
}

export interface StagingObjectMetadata {
  readonly bytes: number;
  readonly contentType: string;
}

export interface MediaObjectStorage {
  createSignedUpload(path: string): Promise<SignedMediaUpload>;
  headStaging(path: string): Promise<StagingObjectMetadata | null>;
  downloadStaging(path: string, destination: string): Promise<void>;
  uploadVariant(path: string, source: string): Promise<void>;
  deleteStaging(path: string): Promise<void>;
}
