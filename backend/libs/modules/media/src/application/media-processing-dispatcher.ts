import type { MediaJobProducer } from './ports/media-job.producer.js';

export class MediaProcessingDispatcher {
  constructor(private readonly producer: MediaJobProducer) {}

  dispatch(mediaId: string): Promise<void> {
    return this.producer.enqueueImage(mediaId);
  }
}
