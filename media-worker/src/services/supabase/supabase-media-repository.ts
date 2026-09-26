import { SupabaseClient } from '@supabase/supabase-js';
import { MediaRepository, PostMediaRecord } from '../core/media-repository';
import { TransientMediaError } from '../core/errors';

export class SupabaseMediaRepository implements MediaRepository {
  constructor(private readonly supabase: SupabaseClient) {}

  async fetchMedia(mediaId: string): Promise<PostMediaRecord | null> {
    const { data, error } = await this.supabase
      .from('post_media')
      .select('media_id, post_id, status, staging_path, final_prefix, pipeline_version, processing_attempts, optimization_attempts, variants')
      .eq('media_id', mediaId)
      .maybeSingle();

    if (error) {
      throw new TransientMediaError(`Failed to fetch media ${mediaId}: ${error.message}`, error);
    }
    if (!data) return null;

    return {
      mediaId: data.media_id,
      postId: data.post_id,
      status: data.status,
      stagingPath: data.staging_path,
      finalPrefix: data.final_prefix,
      pipelineVersion: data.pipeline_version,
      processingAttempts: data.processing_attempts ?? 0,
      optimizationAttempts: data.optimization_attempts ?? 0,
      variants: (data.variants as Record<string, any>) ?? {},
    };
  }

  async setProcessingFeed(mediaId: string, attempts: number): Promise<void> {
    const { error } = await this.supabase
      .from('post_media')
      .update({
        status: 'processing_feed',
        processing_attempts: attempts,
        processing_started_at: new Date().toISOString(),
      })
      .eq('media_id', mediaId);

    if (error) {
      throw new TransientMediaError(`Failed to set processing_feed: ${error.message}`, error);
    }
  }

  async markFeedReady(params: {
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
  }): Promise<void> {
    const { error } = await this.supabase.rpc('mark_media_feed_ready', {
      p_media_id: params.mediaId,
      p_source_width: params.sourceWidth,
      p_source_height: params.sourceHeight,
      p_display_width: params.displayWidth,
      p_display_height: params.displayHeight,
      p_blurhash: params.blurhash,
      p_variants: {
        '1080': params.variant1080,
      },
    });

    if (error) {
      throw new TransientMediaError(`Failed to mark media feed ready: ${error.message}`, error);
    }
  }

  async setOptimizing(mediaId: string, attempts: number): Promise<void> {
    const { error } = await this.supabase
      .from('post_media')
      .update({
        status: 'optimizing',
        optimization_attempts: attempts,
      })
      .eq('media_id', mediaId);

    if (error) {
      throw new TransientMediaError(`Failed to set optimizing: ${error.message}`, error);
    }
  }

  async markOptimized(mediaId: string, variants: Record<string, any>): Promise<void> {
    const { error } = await this.supabase.rpc('mark_media_optimized', {
      p_media_id: mediaId,
      p_variants: variants,
    });

    if (error) {
      throw new TransientMediaError(`Failed to mark media optimized: ${error.message}`, error);
    }
  }

  async recordJobOutcome(jobId: string, status: 'succeeded' | 'failed', error?: string): Promise<void> {
    await this.supabase.rpc('record_media_job_outcome', {
      p_job_id: jobId,
      p_status: status,
      p_error: error ?? null,
    });
  }

  async markProcessingFailed(mediaId: string, error: string): Promise<void> {
    await this.supabase
      .from('post_media')
      .update({
        status: 'processing_failed',
        last_processing_error: error,
      })
      .eq('media_id', mediaId);
  }

  async markOptimizationFailed(mediaId: string, error: string): Promise<void> {
    await this.supabase
      .from('post_media')
      .update({
        status: 'optimization_failed',
        last_processing_error: error,
      })
      .eq('media_id', mediaId);
  }
}
