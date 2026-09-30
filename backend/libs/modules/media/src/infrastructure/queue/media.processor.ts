import { Processor, WorkerHost } from '@nestjs/bullmq';
import { UnrecoverableError, type Job } from 'bullmq';
import {
  MEDIA_JOB_NAMES,
  MEDIA_QUEUE_NAME,
  type ProcessImageJobV1,
} from '../../contracts/media-job.contract.js';
import {
  PermanentMediaProcessingError,
  ProcessImageService,
} from '../../application/process-image.service.js';

@Processor(MEDIA_QUEUE_NAME)
export class MediaProcessor extends WorkerHost {
  constructor(private readonly processImage: ProcessImageService) {
    super();
  }

  async process(job: Job<ProcessImageJobV1>): Promise<void> {
    if (
      job.name !== MEDIA_JOB_NAMES.processImage ||
      job.data.schemaVersion !== 1
    ) {
      throw new UnrecoverableError('unsupported_media_job');
    }
    try {
      await this.processImage.execute(job.data.mediaId, job.attemptsMade + 1);
    } catch (error) {
      if (error instanceof PermanentMediaProcessingError) {
        throw new UnrecoverableError(error.message);
      }
      throw error;
    }
  }
}
