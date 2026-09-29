import type { Queue } from 'bullmq';

import type { MediaJobProducer } from '../../application/post-command.ports.js';

type MediaQueue = Pick<Queue, 'add'>;

export class BullMqMediaJobProducer implements MediaJobProducer {
  constructor(private readonly queue: MediaQueue) {}

  async enqueueImage(mediaId: string): Promise<void> {
    await this.queue.add(
      'process-image',
      { schemaVersion: 1, mediaId },
      { jobId: `media-${mediaId}` },
    );
  }
}
