import { Module } from '@nestjs/common';
import { MediaWorkerModule } from '@modules/media';

import { PlatformConfigModule } from '../../../libs/platform/src/config/platform-config.module.js';
import { DatabaseModule } from '../../../libs/platform/src/database/database.module.js';
import { PlatformLifecycleModule } from '../../../libs/platform/src/lifecycle/platform-lifecycle.module.js';
import { LoggingModule } from '../../../libs/platform/src/logging/logging.module.js';
import { WorkerLifecycleService } from './lifecycle/worker-lifecycle.service.js';

@Module({
  imports: [
    PlatformConfigModule,
    LoggingModule,
    DatabaseModule,
    PlatformLifecycleModule,
    MediaWorkerModule,
  ],
  providers: [WorkerLifecycleService],
})
export class WorkerModule {}
