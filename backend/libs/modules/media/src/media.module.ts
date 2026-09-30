import { BullModule, getQueueToken } from '@nestjs/bullmq';
import { Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createClient } from '@supabase/supabase-js';
import type { Queue } from 'bullmq';

import type { PlatformConfiguration } from '../../../platform/src/config/configuration.js';
import { PlatformConfigModule } from '../../../platform/src/config/platform-config.module.js';
import { DatabaseModule } from '../../../platform/src/database/database.module.js';
import { DatabaseExecutorService } from '../../../platform/src/database/database-executor.service.js';
import { QueueModule } from '../../../platform/src/queue/queue.module.js';

import {
  MEDIA_QUEUE_NAME,
  type ProcessImageJobV1,
} from './contracts/media-job.contract.js';
import {
  IMAGE_TRANSFORMER,
  type ImageTransformer,
} from './application/ports/image-transformer.js';
import {
  MEDIA_JOB_PRODUCER,
  type MediaJobProducer,
} from './application/ports/media-job.producer.js';
import {
  MEDIA_OBJECT_STORAGE,
  type MediaObjectStorage,
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
  MEDIA_RUNTIME,
} from './application/ports/media-runtime.js';

import { MediaProcessingScheduler } from './application/media-processing-scheduler.js';
import { MediaUploadService } from './application/media-upload.service.js';
import { ProcessImageService } from './application/process-image.service.js';
import { BullMqMediaRuntimeService } from './infrastructure/queue/bullmq-media-runtime.service.js';

import { SharpImageTransformer } from './infrastructure/image/sharp-image-transformer.js';
import { PostgresMediaRepository } from './infrastructure/persistence/postgres-media.repository.js';
import { BullMqMediaJobProducer } from './infrastructure/queue/bullmq-media-job.producer.js';
import { ScratchWorkspaceService } from './infrastructure/scratch/scratch-workspace.service.js';
import { SupabaseMediaStorageService } from './infrastructure/storage/supabase-media-storage.service.js';

@Module({
  imports: [
    PlatformConfigModule,
    DatabaseModule,
    QueueModule,
    BullModule.registerQueue({
      name: MEDIA_QUEUE_NAME,
      forceDisconnectOnShutdown: true,
    }),
  ],
  providers: [
    // Internal infrastructure adapters
    {
      provide: MEDIA_REPOSITORY,
      inject: [DatabaseExecutorService],
      useFactory: (db: DatabaseExecutorService) => new PostgresMediaRepository(db),
    },
    {
      provide: MEDIA_OBJECT_STORAGE,
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
      provide: MEDIA_JOB_PRODUCER,
      inject: [getQueueToken(MEDIA_QUEUE_NAME)],
      useFactory: (queue: Queue<ProcessImageJobV1>) => new BullMqMediaJobProducer(queue),
    },

    // Public application services
    {
      provide: MediaUploadService,
      inject: [MEDIA_OBJECT_STORAGE],
      useFactory: (storage: MediaObjectStorage) => new MediaUploadService(storage),
    },
    {
      provide: MediaProcessingScheduler,
      inject: [MEDIA_JOB_PRODUCER],
      useFactory: (producer: MediaJobProducer) => new MediaProcessingScheduler(producer),
    },
    {
      provide: ProcessImageService,
      inject: [
        MEDIA_REPOSITORY,
        MEDIA_OBJECT_STORAGE,
        IMAGE_TRANSFORMER,
        SCRATCH_WORKSPACE,
      ],
      useFactory: (
        repository: MediaRepository,
        storage: MediaObjectStorage,
        transformer: ImageTransformer,
        scratch: ScratchWorkspace,
      ) => new ProcessImageService(repository, storage, transformer, scratch),
    },
    {
      provide: MEDIA_RUNTIME,
      inject: [getQueueToken(MEDIA_QUEUE_NAME)],
      useFactory: (queue: Queue) => new BullMqMediaRuntimeService(queue),
    },
  ],
  exports: [
    MediaUploadService,
    MediaProcessingScheduler,
    ProcessImageService,
    MEDIA_RUNTIME,
  ],
})
export class MediaModule {}
