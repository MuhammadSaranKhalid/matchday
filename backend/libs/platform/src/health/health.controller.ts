import { Controller, Get, VERSION_NEUTRAL } from '@nestjs/common';
import {
  HealthCheck,
  HealthCheckService,
  type HealthCheckResult,
} from '@nestjs/terminus';

import { ReadinessService } from '../lifecycle/readiness.service.js';
import { PostgresHealthIndicator } from '../database/postgres-health.indicator.js';
import { RedisHealthIndicator } from '../redis/redis-health.indicator.js';

@Controller({ path: 'health', version: VERSION_NEUTRAL })
export class HealthController {
  constructor(
    private readonly health: HealthCheckService,
    private readonly readiness: ReadinessService,
    private readonly postgres: PostgresHealthIndicator,
    private readonly redis: RedisHealthIndicator,
  ) {}

  @Get('live')
  @HealthCheck()
  live(): Promise<HealthCheckResult> {
    return this.health.check([async () => ({ process: { status: 'up' } })]);
  }

  @Get('ready')
  @HealthCheck()
  ready(): Promise<HealthCheckResult> {
    return this.health.check([
      async () => {
        const [postgres, redis] = await Promise.all([
          this.postgres.isHealthy('postgres'),
          this.redis.isHealthy('redis'),
        ]);
        const status = this.readiness.isReady() ? 'up' as const : 'down' as const;
        return {
          foundation: { status },
          queues: { status },
          ...postgres,
          ...redis,
        };
      },
    ]);
  }
}
