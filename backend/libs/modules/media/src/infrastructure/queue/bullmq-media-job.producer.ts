import type { Queue } from 'bullmq';

import type { MediaJobProducer } from '../../application/ports/media-job.producer.js';
import {
  MEDIA_JOB_NAMES,
  type ProcessImageJobV1,
} from '../../contracts/media-job.contract.js';

type MediaQueue = Pick<Queue<ProcessImageJobV1>, 'add'>;

export class BullMqMediaJobProducer implements MediaJobProducer {
  constructor(private readonly queue: MediaQueue) {}

  async enqueueImage(mediaId: string): Promise<void> {
    const payload: ProcessImageJobV1 = { schemaVersion: 1, mediaId };
    await this.queue.add(MEDIA_JOB_NAMES.processImage, payload, {
      jobId: `media-${mediaId}`,
    });
  }
}

