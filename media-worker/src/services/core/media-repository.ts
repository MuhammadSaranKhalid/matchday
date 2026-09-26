export interface PostMediaRecord {
  mediaId: string;
  postId: string;
  status: string;
  stagingPath: string;
  finalPrefix: string;
  pipelineVersion: number;
  processingAttempts: number;
  optimizationAttempts: number;
  variants: Record<string, any>;
}

export interface MediaRepository {
  fetchMedia(mediaId: string): Promise<PostMediaRecord | null>;
  setProcessingFeed(mediaId: string, attempts: number): Promise<void>;
  markFeedReady(params: {
    mediaId: string;
    sourceWidth: number;
    sourceHeight: number;
    displayWidth: number;
    displayHeight: number;
    blurhash: string;
    variant1080: {
      path: string;
      width: number;
      height: number;
      bytes: number;
      mime: string;
    };
  }): Promise<void>;
  setOptimizing(mediaId: string, attempts: number): Promise<void>;
  markOptimized(mediaId: string, variants: Record<string, any>): Promise<void>;
  recordJobOutcome(jobId: string, status: 'succeeded' | 'failed', error?: string): Promise<void>;
  markProcessingFailed(mediaId: string, error: string): Promise<void>;
  markOptimizationFailed(mediaId: string, error: string): Promise<void>;
}
