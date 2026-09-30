import type { Job, Queue } from 'bullmq';

import type { MediaJobProducer } from '../../application/ports/media-job.producer.js';
import {
  MEDIA_JOB_NAMES,
  type ProcessImageJobV1,
  type ProcessImageJobV2,
} from '../../contracts/media-job.contract.js';

type SupportedJob = ProcessImageJobV2 | ProcessImageJobV1;
type MediaJob = Pick<Job<SupportedJob>, 'getState' | 'remove'>;
type MediaQueue = Pick<Queue<SupportedJob>, 'add'> & {
  getJob(jobId: string): Promise<MediaJob | undefined | null>;
};

export class BullMqMediaJobProducer implements MediaJobProducer {
  constructor(private readonly queue: MediaQueue) {}

  async enqueueImage(mediaId: string, generation = 1): Promise<void> {
    const jobId = `media-${mediaId}`;
    const existingJob = await this.queue.getJob(jobId);

    if (existingJob) {
      const state = await existingJob.getState();
      if (
        state === 'active' ||
        state === 'waiting' ||
        state === 'delayed' ||
        state === 'waiting-children'
      ) {
        return;
      }
      try {
        await existingJob.remove();
      } catch {
        // Job may have been removed concurrently.
      }
    }

    const payload: ProcessImageJobV2 = { schemaVersion: 2, mediaId, generation };
    await this.queue.add(MEDIA_JOB_NAMES.processImage, payload, {
      jobId,
    });
  }
}

