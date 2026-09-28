import { Module } from '@nestjs/common';

import { PlatformConfigModule } from '../../../libs/platform/src/config/platform-config.module.js';
import { LoggingModule } from '../../../libs/platform/src/logging/logging.module.js';

@Module({
  imports: [PlatformConfigModule, LoggingModule],
})
export class WorkerModule {}
