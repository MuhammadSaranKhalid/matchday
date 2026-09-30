export const MEDIA_QUEUE_NAME = 'media' as const;

export const MEDIA_JOB_NAMES = {
  processImage: 'process-image',
} as const;

export interface ProcessImageJobV1 {
  readonly schemaVersion: 1;
  readonly mediaId: string;
}

export interface ProcessImageJobV2 {
  readonly schemaVersion: 2;
  readonly mediaId: string;
  readonly generation: number;
}
