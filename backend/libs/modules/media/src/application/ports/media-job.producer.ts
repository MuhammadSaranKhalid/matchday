export const MEDIA_JOB_PRODUCER = Symbol('MEDIA_JOB_PRODUCER');

export interface MediaJobProducer {
  enqueueImage(mediaId: string, generation?: number): Promise<void>;
}
