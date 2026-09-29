import { Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

import type { PlatformConfiguration } from '../config/configuration.js';
import { RedisConnectionsService } from './redis-connections.service.js';
import { RedisHealthIndicator } from './redis-health.indicator.js';

@Module({
  providers: [
    {
      provide: RedisConnectionsService,
      inject: [ConfigService],
      useFactory: (configuration: ConfigService<PlatformConfiguration, true>) =>
        new RedisConnectionsService(configuration.get('redis', { infer: true })),
    },
    {
      provide: RedisHealthIndicator,
      inject: [RedisConnectionsService],
      useFactory: (connections: RedisConnectionsService) => new RedisHealthIndicator(connections),
    },
  ],
  exports: [RedisConnectionsService, RedisHealthIndicator],
})
export class RedisModule {}
