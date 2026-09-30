import { Processor, WorkerHost } from '@nestjs/bullmq';
import { UnrecoverableError, type Job } from 'bullmq';
import {
  MEDIA_JOB_NAMES,
  MEDIA_QUEUE_NAME,
  type ProcessImageJob,
} from '../../contracts/media-job.contract.js';
import {
  PermanentMediaProcessingError,
  ProcessImageService,
} from '../../application/process-image.service.js';

// V1: concurrency deliberately fixed at 1. Increase only after Sharp load testing.
export const MEDIA_WORKER_CONCURRENCY = 1;

@Processor(MEDIA_QUEUE_NAME, { concurrency: MEDIA_WORKER_CONCURRENCY })
export class MediaProcessor extends WorkerHost {
  constructor(private readonly processImage: ProcessImageService) {
    super();
  }

  async process(job: Job<ProcessImageJob>): Promise<void> {
    if (
      job.name !== MEDIA_JOB_NAMES.processImage ||
      job.data.schemaVersion !== 1
    ) {
      throw new UnrecoverableError('unsupported_media_job');
    }
    try {
      await this.processImage.execute(
        job.data.mediaId,
        job.attemptsMade + 1,
        job.opts?.attempts ?? 3,
      );
    } catch (error) {
      if (error instanceof PermanentMediaProcessingError) {
        throw new UnrecoverableError(error.message);
      }
      throw error;
    }
  }
}
