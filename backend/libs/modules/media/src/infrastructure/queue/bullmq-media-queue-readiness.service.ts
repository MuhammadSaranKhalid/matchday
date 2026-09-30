import { Inject, Injectable } from '@nestjs/common';
import { getQueueToken } from '@nestjs/bullmq';
import type { Queue } from 'bullmq';

import { MEDIA_QUEUE_NAME } from '../../contracts/media-job.contract.js';
import type { MediaQueueReadiness } from '../../application/ports/media-queue-readiness.js';

@Injectable()
export class BullMqMediaQueueReadinessService implements MediaQueueReadiness {
  constructor(
    @Inject(getQueueToken(MEDIA_QUEUE_NAME)) private readonly queue: Queue,
  ) {}

  waitUntilReady(): Promise<void> {
    return this.queue.waitUntilReady();
  }
}
