import { BullModule, getQueueToken } from '@nestjs/bullmq';
import { Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createClient } from '@supabase/supabase-js';
import type { Queue } from 'bullmq';

import type { PlatformConfiguration } from '../../../platform/src/config/configuration.js';
import { PlatformConfigModule } from '../../../platform/src/config/platform-config.module.js';
import { DatabaseModule } from '../../../platform/src/database/database.module.js';
import { DatabaseExecutorService } from '../../../platform/src/database/database-executor.service.js';
import { QueueWorkerModule } from '../../../platform/src/queue/queue.module.js';

import {
  MEDIA_QUEUE_NAME,
} from './contracts/media-job.contract.js';
import {
  IMAGE_TRANSFORMER,
  type ImageTransformer,
} from './application/ports/image-transformer.js';
import {
  MEDIA_PROCESSING_STORAGE,
  type MediaProcessingStorage,
} from './application/ports/media-object-storage.js';
import {
  MEDIA_REPOSITORY,
  type MediaRepository,
} from './application/ports/media-repository.js';
import {
  SCRATCH_WORKSPACE,
  type ScratchWorkspace,
} from './application/ports/scratch-workspace.js';
import {
  MEDIA_QUEUE_READINESS,
} from './application/ports/media-queue-readiness.js';

import { ProcessImageService } from './application/process-image.service.js';
import { SharpImageTransformer } from './infrastructure/image/sharp-image-transformer.js';
import { PostgresMediaRepository } from './infrastructure/persistence/postgres-media.repository.js';
import { BullMqMediaQueueReadinessService } from './infrastructure/queue/bullmq-media-queue-readiness.service.js';
import { ScratchWorkspaceService } from './infrastructure/scratch/scratch-workspace.service.js';
import { SupabaseMediaStorageService } from './infrastructure/storage/supabase-media-storage.service.js';
import { MediaProcessor } from './presentation/queue/media.processor.js';

@Module({
  imports: [
    PlatformConfigModule,
    DatabaseModule,
    QueueWorkerModule,
    BullModule.registerQueue({
      name: MEDIA_QUEUE_NAME,
      forceDisconnectOnShutdown: true,
    }),
  ],
  providers: [
    {
      provide: MEDIA_REPOSITORY,
      inject: [DatabaseExecutorService],
      useFactory: (db: DatabaseExecutorService) => new PostgresMediaRepository(db),
    },
    {
      provide: MEDIA_PROCESSING_STORAGE,
      inject: [ConfigService],
      useFactory: (configuration: ConfigService<PlatformConfiguration, true>) => {
        const storage = configuration.get('mediaStorage', { infer: true });
        const client = createClient(storage.supabaseUrl, storage.secretKey, {
          auth: {
            autoRefreshToken: false,
            detectSessionInUrl: false,
            persistSession: false,
          },
        });
        return new SupabaseMediaStorageService(client);
      },
    },
    {
      provide: IMAGE_TRANSFORMER,
      useFactory: () => new SharpImageTransformer(),
    },
    {
      provide: SCRATCH_WORKSPACE,
      useFactory: () => new ScratchWorkspaceService(),
    },
    {
      provide: ProcessImageService,
      inject: [
        MEDIA_REPOSITORY,
        MEDIA_PROCESSING_STORAGE,
        IMAGE_TRANSFORMER,
        SCRATCH_WORKSPACE,
      ],
      useFactory: (
        repository: MediaRepository,
        storage: MediaProcessingStorage,
        transformer: ImageTransformer,
        scratch: ScratchWorkspace,
      ) => new ProcessImageService(repository, storage, transformer, scratch),
    },
    {
      provide: MEDIA_QUEUE_READINESS,
      inject: [getQueueToken(MEDIA_QUEUE_NAME)],
      useFactory: (queue: Queue) => new BullMqMediaQueueReadinessService(queue),
    },
    MediaProcessor,
  ],
  exports: [
    MEDIA_QUEUE_READINESS,
  ],
})
export class MediaWorkerModule {}
