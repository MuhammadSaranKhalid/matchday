import crypto from 'node:crypto';
import { supabase } from './supabase';
import { QueueJob, finishJob, retryJob } from './queue';
import { SupabaseMediaRepository } from './services/supabase/supabase-media-repository';
import { SupabaseMediaStorage } from './services/supabase/supabase-media-storage';
import { executeMediaJob } from './services/core/execute-job';
import { PermanentMediaError } from './services/core/errors';
import { MediaProcessingJob } from './services/core/contracts';

const repo = new SupabaseMediaRepository(supabase);
const storage = new SupabaseMediaStorage(supabase);
const deps = { repo, storage };

const FEED_RETRY_DELAYS = [15, 30, 60, 120, 300];
const OPTIMIZE_RETRY_DELAYS = [30, 60, 120];

export async function processFeedJob(job: QueueJob): Promise<void> {
  const mediaId = job.message.mediaId || job.message.media_id;
  const jobId = job.message.jobId || crypto.randomUUID();
  const pipelineVersion = job.message.pipelineVersion || job.message.pipeline_version || 1;

  if (!mediaId) {
    console.error('[processFeedJob] Job missing mediaId, archiving:', job);
    await finishJob('feed', job.msg_id);
    return;
  }

  const canonicalJob: MediaProcessingJob = {
    schemaVersion: 1,
    jobId,
    mediaId,
    stage: 'feed',
    pipelineVersion,
  };

  try {
    await executeMediaJob(canonicalJob, deps);
    await repo.recordJobOutcome(jobId, 'succeeded');
    await finishJob('feed', job.msg_id);
  } catch (error: any) {
    console.error(`[processFeedJob] Error processing media ${mediaId}:`, error);

    const isPermanent = error instanceof PermanentMediaError;
    const attempts = job.read_ct || 1;

    if (isPermanent || attempts >= 5) {
      const errorMsg = error.message || 'Exceeded 5 processing attempts';
      await repo.recordJobOutcome(jobId, 'failed', errorMsg);
      await repo.markProcessingFailed(mediaId, errorMsg);
      await finishJob('feed', job.msg_id);
    } else {
      const delay = FEED_RETRY_DELAYS[attempts - 1] || 60;
      await retryJob('feed', job.msg_id, delay);
    }
  }
}

export async function processOptimizeJob(job: QueueJob): Promise<void> {
  const mediaId = job.message.mediaId || job.message.media_id;
  const jobId = job.message.jobId || crypto.randomUUID();
  const pipelineVersion = job.message.pipelineVersion || job.message.pipeline_version || 1;

  if (!mediaId) {
    await finishJob('optimize', job.msg_id);
    return;
  }

  const canonicalJob: MediaProcessingJob = {
    schemaVersion: 1,
    jobId,
    mediaId,
    stage: 'optimize',
    pipelineVersion,
  };

  try {
    await executeMediaJob(canonicalJob, deps);
    await repo.recordJobOutcome(jobId, 'succeeded');
    await finishJob('optimize', job.msg_id);
  } catch (error: any) {
    console.error(`[processOptimizeJob] Error optimizing media ${mediaId}:`, error);

    const isPermanent = error instanceof PermanentMediaError;
    const attempts = job.read_ct || 1;

    if (isPermanent || attempts >= 3) {
      const errorMsg = error.message || 'Exceeded 3 optimization attempts';
      await repo.recordJobOutcome(jobId, 'failed', errorMsg);
      await repo.markOptimizationFailed(mediaId, errorMsg);
      await finishJob('optimize', job.msg_id);
    } else {
      const delay = OPTIMIZE_RETRY_DELAYS[attempts - 1] || 60;
      await retryJob('optimize', job.msg_id, delay);
    }
  }
}
