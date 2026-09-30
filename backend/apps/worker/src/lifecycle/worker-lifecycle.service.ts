import {
  type BeforeApplicationShutdown,
  Inject,
  Injectable,
} from '@nestjs/common';

import {
  MEDIA_RUNTIME,
  type MediaRuntime,
} from '@modules/media';
import { PostgresHealthIndicator } from '../../../../libs/platform/src/database/postgres-health.indicator.js';
import { ReadinessService } from '../../../../libs/platform/src/lifecycle/readiness.service.js';
import { RedisHealthIndicator } from '../../../../libs/platform/src/redis/redis-health.indicator.js';

@Injectable()
export class WorkerLifecycleService
  implements BeforeApplicationShutdown
{
  constructor(
    private readonly readiness: ReadinessService,
    private readonly postgresHealth: PostgresHealthIndicator,
    private readonly redisHealth: RedisHealthIndicator,
    @Inject(MEDIA_RUNTIME) private readonly mediaRuntime: MediaRuntime,
  ) {}

  async initialize(): Promise<void> {
    try {
      const [postgres, redis] = await Promise.all([
        this.postgresHealth.isHealthy('postgres'),
        this.redisHealth.isHealthy('redis'),
        this.mediaRuntime.waitUntilReady(),
      ]);
      if (postgres.postgres?.status !== 'up' || redis.redis?.status !== 'up') {
        throw new Error('dependency check failed');
      }
    } catch {
      throw new Error('Worker infrastructure is unavailable');
    }
    this.readiness.markReady();
  }

  beforeApplicationShutdown(_signal?: string): Promise<void> {
    this.readiness.markStopping();
    return Promise.resolve();
  }
}
