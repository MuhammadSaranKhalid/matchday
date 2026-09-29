import { Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

import { ProcessImageService } from '../../../libs/media/src/application/process-image.service.js';
import { MEDIA_OBJECT_STORAGE, type MediaObjectStorage } from '../../../libs/media/src/application/ports/media-object-storage.js';
import { PostgresMediaRepository } from '../../../libs/media/src/infrastructure/postgres/postgres-media.repository.js';
import { ScratchWorkspaceService } from '../../../libs/media/src/infrastructure/scratch/scratch-workspace.service.js';
import { SharpImageTransformer } from '../../../libs/media/src/infrastructure/sharp/sharp-image-transformer.js';
import { MediaModule } from '../../../libs/media/src/media.module.js';
import { PlatformConfigModule } from '../../../libs/platform/src/config/platform-config.module.js';
import { AuthModule } from '../../../libs/platform/src/auth/auth.module.js';
import { DatabaseModule } from '../../../libs/platform/src/database/database.module.js';
import { QueueModule } from '../../../libs/platform/src/queue/queue.module.js';
import { RedisModule } from '../../../libs/platform/src/redis/redis.module.js';
import { HealthModule } from '../../../libs/platform/src/health/health.module.js';
import { LoggingModule } from '../../../libs/platform/src/logging/logging.module.js';
import { WorkerLifecycleService } from './worker-lifecycle.service.js';
import { MediaProcessor } from './media/media.processor.js';

@Module({
  imports: [
    PlatformConfigModule,
    LoggingModule,
    AuthModule,
    DatabaseModule,
    RedisModule,
    QueueModule,
    HealthModule,
    MediaModule,
  ],
  providers: [
    WorkerLifecycleService,
    MediaProcessor,
    PostgresMediaRepository,
    SharpImageTransformer,
    {
      provide: ScratchWorkspaceService,
      inject: [ConfigService],
      useFactory: () => new ScratchWorkspaceService(),
    },
    {
      provide: ProcessImageService,
      inject: [
        PostgresMediaRepository,
        MEDIA_OBJECT_STORAGE,
        SharpImageTransformer,
        ScratchWorkspaceService,
      ],
      useFactory: (
        repository: PostgresMediaRepository,
        storage: MediaObjectStorage,
        transformer: SharpImageTransformer,
        scratch: ScratchWorkspaceService,
      ) => new ProcessImageService(repository, storage, transformer, scratch),
    },
  ],
})
export class WorkerModule {}
