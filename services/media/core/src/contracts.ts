export interface MediaProcessingJob {
  schemaVersion: 1;
  jobId: string;
  mediaId: string;
  stage: 'feed' | 'optimize';
  pipelineVersion: number;
}

export interface ImageVariantInfo {
  buffer: Buffer;
  width: number;
  height: number;
  bytes: number;
  mime: string;
}

export interface FeedReadyResult {
  sourceWidth: number;
  sourceHeight: number;
  displayWidth: number;
  displayHeight: number;
  blurhash: string;
  variant1080: ImageVariantInfo;
}

export interface OptimizedVariantsResult {
  variants: Record<string, ImageVariantInfo>;
}
