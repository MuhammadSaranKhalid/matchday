import { Module } from '@nestjs/common';
import { TerminusModule } from '@nestjs/terminus';

import { DatabaseModule } from '../database/database.module.js';
import { PlatformLifecycleModule } from '../lifecycle/platform-lifecycle.module.js';
import { RedisModule } from '../redis/redis.module.js';
import { HealthController } from './health.controller.js';

@Module({
  imports: [TerminusModule, DatabaseModule, RedisModule, PlatformLifecycleModule],
  controllers: [HealthController],
  exports: [PlatformLifecycleModule],
})
export class HealthModule {}
