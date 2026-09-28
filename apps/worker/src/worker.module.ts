import { Module } from '@nestjs/common';

import { PlatformConfigModule } from '../../../libs/platform/src/config/platform-config.module.js';
import { HealthModule } from '../../../libs/platform/src/health/health.module.js';
import { LoggingModule } from '../../../libs/platform/src/logging/logging.module.js';
import { WorkerLifecycleService } from './worker-lifecycle.service.js';

@Module({
  imports: [PlatformConfigModule, LoggingModule, HealthModule],
  providers: [WorkerLifecycleService],
})
export class WorkerModule {}
