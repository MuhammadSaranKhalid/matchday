import { Module } from '@nestjs/common';
import { MediaModule } from '@modules/media';

import { PlatformConfigModule } from '../../../libs/platform/src/config/platform-config.module.js';
import { DatabaseModule } from '../../../libs/platform/src/database/database.module.js';
import { HealthModule } from '../../../libs/platform/src/health/health.module.js';
import { LoggingModule } from '../../../libs/platform/src/logging/logging.module.js';
import { QueueModule } from '../../../libs/platform/src/queue/queue.module.js';
import { RedisModule } from '../../../libs/platform/src/redis/redis.module.js';
import { WorkerLifecycleService } from './lifecycle/worker-lifecycle.service.js';
import { MediaProcessor } from './processors/media.processor.js';

@Module({
  imports: [
    PlatformConfigModule,
    LoggingModule,
    DatabaseModule,
    RedisModule,
    QueueModule,
    HealthModule,
    MediaModule,
  ],
  providers: [WorkerLifecycleService, MediaProcessor],
})
export class WorkerModule {}
