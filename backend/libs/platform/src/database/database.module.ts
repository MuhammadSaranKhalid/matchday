import { Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

import type { PlatformConfiguration } from '../config/configuration.js';
import { DatabaseExecutorService } from './database-executor.service.js';
import { PostgresHealthIndicator } from './postgres-health.indicator.js';
import { PostgresPoolService } from './postgres-pool.service.js';

@Module({
  providers: [
    {
      provide: PostgresPoolService,
      inject: [ConfigService],
      useFactory: (configuration: ConfigService<PlatformConfiguration, true>) =>
        new PostgresPoolService(configuration.get('database', { infer: true })),
    },
    {
      provide: DatabaseExecutorService,
      inject: [PostgresPoolService],
      useFactory: (database: PostgresPoolService) => new DatabaseExecutorService(database),
    },
    {
      provide: PostgresHealthIndicator,
      inject: [PostgresPoolService],
      useFactory: (database: PostgresPoolService) => new PostgresHealthIndicator(database),
    },
  ],
  exports: [DatabaseExecutorService, PostgresHealthIndicator],
})
export class DatabaseModule {}
