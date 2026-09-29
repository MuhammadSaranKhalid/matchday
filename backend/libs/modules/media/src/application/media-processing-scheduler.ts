import type { MediaJobProducer } from './ports/media-job.producer.js';

export class MediaProcessingScheduler {
  constructor(private readonly producer: MediaJobProducer) {}

  scheduleProcessing(mediaId: string): Promise<void> {
    return this.producer.enqueueImage(mediaId);
  }
}
