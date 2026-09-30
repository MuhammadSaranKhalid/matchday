import type { Queue } from 'bullmq';

import type { MediaJobProducer } from '../../application/ports/media-job.producer.js';
import {
  MEDIA_JOB_NAMES,
  type ProcessImageJob,
} from '../../contracts/media-job.contract.js';

type MediaQueue = Pick<Queue<ProcessImageJob>, 'add'>;

export class BullMqMediaJobProducer implements MediaJobProducer {
  constructor(private readonly queue: MediaQueue) {}

  async enqueueImage(mediaId: string): Promise<void> {
    await this.queue.add(
      MEDIA_JOB_NAMES.processImage,
      {
        schemaVersion: 1,
        mediaId,
      },
      {
        jobId: `media-${mediaId}`,
      },
    );
  }
}

