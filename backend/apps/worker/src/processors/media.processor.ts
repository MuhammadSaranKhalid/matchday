import { Processor, WorkerHost } from '@nestjs/bullmq';
import { UnrecoverableError, type Job } from 'bullmq';

import {
  PermanentMediaProcessingError,
  ProcessImageService,
} from '../../../libs/modules/media/src/application/process-image.service.js';

interface ProcessImageJob {
  readonly schemaVersion: 1;
  readonly mediaId: string;
}

@Processor('media')
export class MediaProcessor extends WorkerHost {
  constructor(private readonly processImage: ProcessImageService) {
    super();
  }

  async process(job: Job<ProcessImageJob>): Promise<void> {
    if (job.name !== 'process-image' || job.data.schemaVersion !== 1) {
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
