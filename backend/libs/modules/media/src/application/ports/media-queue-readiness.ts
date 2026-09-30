export const MEDIA_QUEUE_READINESS = Symbol('MEDIA_QUEUE_READINESS');

export interface MediaQueueReadiness {
  waitUntilReady(): Promise<void>;
}
