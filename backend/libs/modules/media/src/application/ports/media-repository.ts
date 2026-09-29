export const MEDIA_REPOSITORY = Symbol('MEDIA_REPOSITORY');

import type { TransformedImage } from './image-transformer.js';
export interface ClaimedMedia {
  readonly mediaId: string;
  readonly postId: string;
  readonly stagingPath: string;
  readonly finalPrefix: string;
  readonly pipelineVersion: number;
  readonly attempt: number;
}

export interface MediaClaimResult {
  readonly claimed: boolean;
  readonly status: string;
  readonly media?: ClaimedMedia;
}

export interface MediaRepository {
  claim(mediaId: string): Promise<MediaClaimResult>;
  releaseForRetry(mediaId: string, error: string): Promise<void>;
  markFailed(mediaId: string, error: string): Promise<void>;
  markReady(mediaId: string, image: TransformedImage): Promise<void>;
}
