import { Processor, WorkerHost } from '@nestjs/bullmq';
import { UnrecoverableError, type Job } from 'bullmq';
import {
  MEDIA_JOB_NAMES,
  MEDIA_QUEUE_NAME,
  type ProcessImageJobV1,
  type ProcessImageJobV2,
} from '../../contracts/media-job.contract.js';
import {
  PermanentMediaProcessingError,
  ProcessImageService,
} from '../../application/process-image.service.js';

type SupportedJob = ProcessImageJobV1 | ProcessImageJobV2;

export const MEDIA_WORKER_CONCURRENCY = 1;

@Processor(MEDIA_QUEUE_NAME, { concurrency: MEDIA_WORKER_CONCURRENCY })
export class MediaProcessor extends WorkerHost {
  constructor(private readonly processImage: ProcessImageService) {
    super();
  }

  async process(job: Job<SupportedJob>): Promise<void> {
    if (
      job.name !== MEDIA_JOB_NAMES.processImage ||
      (job.data.schemaVersion !== 1 && job.data.schemaVersion !== 2)
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
