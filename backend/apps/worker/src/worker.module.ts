import { Module } from '@nestjs/common';

import { PlatformConfigModule } from '../../../libs/platform/src/config/platform-config.module.js';
import { AuthModule } from '../../../libs/platform/src/auth/auth.module.js';
import { DatabaseModule } from '../../../libs/platform/src/database/database.module.js';
import { QueueModule } from '../../../libs/platform/src/queue/queue.module.js';
import { RedisModule } from '../../../libs/platform/src/redis/redis.module.js';
import { HealthModule } from '../../../libs/platform/src/health/health.module.js';
import { LoggingModule } from '../../../libs/platform/src/logging/logging.module.js';
import { WorkerLifecycleService } from './worker-lifecycle.service.js';

@Module({
  imports: [
    PlatformConfigModule,
    LoggingModule,
    AuthModule,
    DatabaseModule,
    RedisModule,
    QueueModule,
    HealthModule,
  ],
  providers: [WorkerLifecycleService],
})
export class WorkerModule {}
