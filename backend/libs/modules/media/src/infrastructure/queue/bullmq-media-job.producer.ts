import type { Queue } from 'bullmq';

import type { MediaJobProducer } from '../../application/ports/media-job.producer.js';
import {
  MEDIA_JOB_NAMES,
  type ProcessImageJobV1,
  type ProcessImageJobV2,
} from '../../contracts/media-job.contract.js';

type MediaQueue = Pick<Queue<ProcessImageJobV2 | ProcessImageJobV1>, 'add'>;

export class BullMqMediaJobProducer implements MediaJobProducer {
  constructor(private readonly queue: MediaQueue) {}

  async enqueueImage(mediaId: string, generation = 1): Promise<void> {
    const payload: ProcessImageJobV2 = { schemaVersion: 2, mediaId, generation };
    await this.queue.add(MEDIA_JOB_NAMES.processImage, payload, {
      jobId: `media-${mediaId}-g${generation}`,
    });
  }
}

