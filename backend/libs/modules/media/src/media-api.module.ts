import { BullModule, getQueueToken } from '@nestjs/bullmq';
import { Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createClient } from '@supabase/supabase-js';
import type { Queue } from 'bullmq';

import type { PlatformConfiguration } from '../../../platform/src/config/configuration.js';
import { PlatformConfigModule } from '../../../platform/src/config/platform-config.module.js';
import { QueueProducerModule } from '../../../platform/src/queue/queue.module.js';

import {
  MEDIA_QUEUE_NAME,
  type ProcessImageJob,
} from './contracts/media-job.contract.js';
import {
  MEDIA_JOB_PRODUCER,
  type MediaJobProducer,
} from './application/ports/media-job.producer.js';
import {
  MEDIA_UPLOAD_STORAGE,
  type MediaUploadStorage,
} from './application/ports/media-object-storage.js';
import { MediaProcessingDispatcher } from './application/media-processing-dispatcher.js';
import { MediaUploadService } from './application/media-upload.service.js';
import { BullMqMediaJobProducer } from './infrastructure/queue/bullmq-media-job.producer.js';
import { SupabaseMediaStorageService } from './infrastructure/storage/supabase-media-storage.service.js';

@Module({
  imports: [
    PlatformConfigModule,
    QueueProducerModule,
    BullModule.registerQueue({
      name: MEDIA_QUEUE_NAME,
      forceDisconnectOnShutdown: true,
    }),
  ],
  providers: [
    {
      provide: MEDIA_UPLOAD_STORAGE,
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
      provide: MEDIA_JOB_PRODUCER,
      inject: [getQueueToken(MEDIA_QUEUE_NAME)],
      useFactory: (queue: Queue<ProcessImageJob>) => new BullMqMediaJobProducer(queue),
    },
    {
      provide: MediaUploadService,
      inject: [MEDIA_UPLOAD_STORAGE],
      useFactory: (storage: MediaUploadStorage) => new MediaUploadService(storage),
    },
    {
      provide: MediaProcessingDispatcher,
      inject: [MEDIA_JOB_PRODUCER],
      useFactory: (producer: MediaJobProducer) => new MediaProcessingDispatcher(producer),
    },
  ],
  exports: [
    MediaUploadService,
    MediaProcessingDispatcher,
  ],
})
export class MediaApiModule {}
