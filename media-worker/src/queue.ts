import { supabase } from './supabase';

export interface QueueJob {
  msg_id: string;
  read_ct: number;
  message: {
    schemaVersion?: number;
    jobId?: string;
    media_id?: string;
    mediaId?: string;
    stage?: 'feed' | 'optimize';
    pipeline_version?: number;
    pipelineVersion?: number;
  };
}

/**
 * Claims pending jobs from Supabase PGMQ queue via service_role RPC.
 */
export async function claimJobs(stage: 'feed' | 'optimize', qty: number): Promise<QueueJob[]> {
  const { data, error } = await supabase.rpc('claim_post_media_jobs', {
    p_stage: stage,
    p_qty: qty,
  });

  if (error) throw error;
  if (!Array.isArray(data)) return [];

  return data as QueueJob[];
}

/**
 * Acknowledges/archives completed job.
 */
export async function finishJob(stage: 'feed' | 'optimize', msgId: string): Promise<void> {
  const { error } = await supabase.rpc('finish_post_media_job', {
    p_stage: stage,
    p_msg_id: parseInt(msgId, 10),
  });

  if (error) {
    console.error(`[finishJob] Error archiving job ${msgId} on ${stage}:`, error);
  }
}

/**
 * Sets visibility timeout for retry with backoff.
 */
export async function retryJob(stage: 'feed' | 'optimize', msgId: string, delaySeconds: number): Promise<void> {
  const { error } = await supabase.rpc('retry_post_media_job', {
    p_stage: stage,
    p_msg_id: parseInt(msgId, 10),
    p_delay_seconds: delaySeconds,
  });

  if (error) {
    console.error(`[retryJob] Error setting retry vt for job ${msgId} on ${stage}:`, error);
  }
}
