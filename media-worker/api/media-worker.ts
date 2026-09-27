import type { VercelRequest, VercelResponse } from '@vercel/node';
import crypto from 'node:crypto';
import { supabase } from '../src/supabase';
import { claimJobs } from '../src/queue';
import { processFeedJob, processOptimizeJob } from '../src/worker';

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'method_not_allowed' });
  }

  // 1. Authenticate worker wake
  const expectedSecret = process.env.MEDIA_WORKER_SECRET;
  const suppliedSecret = req.headers['x-worker-secret'];

  if (!expectedSecret || suppliedSecret !== expectedSecret) {
    return res.status(401).json({ error: 'unauthorized' });
  }

  const workerId = crypto.randomUUID();

  // 2. Acquire concurrency lease slot (max 4 concurrent workers across all instances)
  const { data: slot, error: slotError } = await supabase.rpc('acquire_media_worker_slot', {
    p_worker_id: workerId,
    p_lease_seconds: 70,
  });

  if (slotError) {
    console.error('[media-worker] Error acquiring slot:', slotError);
    return res.status(503).json({ error: 'slot_check_failed', details: slotError.message });
  }

  if (slot == null) {
    // All 4 worker slots are currently busy
    return res.status(202).json({ busy: true, message: 'All worker slots occupied' });
  }

  const startTime = Date.now();
  const feedDeadline = startTime + 33_000; // Stop claiming feed jobs after 33s
  const optimizeDeadline = startTime + 23_000; // Stop claiming heavy optimize jobs after 23s
  let feedProcessed = 0;
  let optimized = 0;

  try {
    while (Date.now() < feedDeadline) {
      // Priority 1: Check high-priority feed queue (max 2 concurrent images)
      const feedJobs = await claimJobs('feed', 2);

      if (feedJobs.length > 0) {
        await Promise.allSettled(feedJobs.map((job) => processFeedJob(job)));
        feedProcessed += feedJobs.length;
        continue;
      }

      // Priority 2: Check low-priority background optimization queue (1 job) only if within budget
      if (Date.now() < optimizeDeadline) {
        const optimizeJobs = await claimJobs('optimize', 1);

        if (optimizeJobs.length > 0) {
          await processOptimizeJob(optimizeJobs[0]);
          optimized++;
          continue;
        }
      }

      // Both queues are empty -> break and finish
      break;
    }

    return res.status(200).json({
      ok: true,
      workerId,
      slot,
      feedProcessed,
      optimized,
    });
  } catch (error: any) {
    console.error('[media-worker] Unexpected worker error:', error);
    return res.status(500).json({ error: 'worker_failed', message: error.message });
  } finally {
    // Always release worker slot
    await supabase.rpc('release_media_worker_slot', {
      p_slot_id: slot,
      p_worker_id: workerId,
    });
  }
}
