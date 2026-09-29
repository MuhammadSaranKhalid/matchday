export const MEDIA_QUEUE_NAME = 'media' as const;

export const MEDIA_JOB_NAMES = {
  processImage: 'process-image',
} as const;

export interface ProcessImageJobV1 {
  readonly schemaVersion: 1;
  readonly mediaId: string;
}
