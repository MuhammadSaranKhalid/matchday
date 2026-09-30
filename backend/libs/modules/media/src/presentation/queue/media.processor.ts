import { OnWorkerEvent, Processor, WorkerHost } from '@nestjs/bullmq';
import { Logger } from '@nestjs/common';
import { UnrecoverableError, type Job } from 'bullmq';

import {
  PermanentMediaProcessingError,
  ProcessImageService,
} from '../../application/process-image.service.js';
import {
  MEDIA_JOB_NAMES,
  MEDIA_QUEUE_NAME,
  type ProcessImageJob,
} from '../../contracts/media-job.contract.js';

// V1: concurrency deliberately fixed at 1. Increase only after Sharp load testing.
export const MEDIA_WORKER_CONCURRENCY = 1;

@Processor(MEDIA_QUEUE_NAME, { concurrency: MEDIA_WORKER_CONCURRENCY })
export class MediaProcessor extends WorkerHost {
  private readonly logger = new Logger(MediaProcessor.name);

  constructor(private readonly processImage: ProcessImageService) {
    super();
  }

  @OnWorkerEvent('completed')
  onCompleted(job: Job<ProcessImageJob>): void {
    const duration = job.finishedOn && job.processedOn ? job.finishedOn - job.processedOn : undefined;
    this.logger.debug?.({
      message: 'Media processing job completed',
      jobId: job.id,
      mediaId: job.data?.mediaId,
      attemptsMade: job.attemptsMade,
      durationMs: duration,
    });
  }

  @OnWorkerEvent('failed')
  onFailed(job: Job<ProcessImageJob> | undefined, error: Error): void {
    this.logger.error({
      message: 'Media processing job failed',
      jobId: job?.id,
      mediaId: job?.data?.mediaId,
      attemptsMade: job?.attemptsMade,
      error: error.message,
      stack: error.stack,
    });
  }

  @OnWorkerEvent('stalled')
  onStalled(jobId: string): void {
    this.logger.warn({
      message: 'Media processing job stalled',
      jobId,
    });
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
