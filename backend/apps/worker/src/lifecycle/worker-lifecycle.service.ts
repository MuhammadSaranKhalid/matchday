import {
  type BeforeApplicationShutdown,
  Inject,
  Injectable,
} from '@nestjs/common';
import { getQueueToken } from '@nestjs/bullmq';
import type { Queue } from 'bullmq';

import { PostgresHealthIndicator } from '../../../../libs/platform/src/database/postgres-health.indicator.js';
import { PostgresPoolService } from '../../../../libs/platform/src/database/postgres-pool.service.js';
import { ReadinessService } from '../../../../libs/platform/src/health/readiness.service.js';
import { RedisConnectionsService } from '../../../../libs/platform/src/redis/redis-connections.service.js';
import { RedisHealthIndicator } from '../../../../libs/platform/src/redis/redis-health.indicator.js';

@Injectable()
export class WorkerLifecycleService
  implements BeforeApplicationShutdown
{
  private keepAlive: ReturnType<typeof setInterval> | undefined;
  private stopping?: Promise<void>;

  constructor(
    private readonly readiness: ReadinessService,
    private readonly postgresHealth: PostgresHealthIndicator,
    private readonly redisHealth: RedisHealthIndicator,
    private readonly redis: RedisConnectionsService,
    private readonly postgres: PostgresPoolService,
    @Inject(getQueueToken('notifications')) private readonly notifications: Queue,
    @Inject(getQueueToken('media')) private readonly media: Queue,
    @Inject(getQueueToken('maintenance')) private readonly maintenance: Queue,
  ) {}

  async initialize(): Promise<void> {
    try {
      const [postgres, redis] = await Promise.all([
        this.postgresHealth.isHealthy('postgres'),
        this.redisHealth.isHealthy('redis'),
        ...this.queues.map((queue) => queue.waitUntilReady()),
      ]);
      if (postgres.postgres?.status !== 'up' || redis.redis?.status !== 'up') {
        throw new Error('dependency check failed');
      }
    } catch {
      throw new Error('Worker infrastructure is unavailable');
    }
    this.readiness.markQueuesInitialized();
    this.keepAlive ??= setInterval(() => undefined, 60_000);
    this.readiness.markReady();
  }

  beforeApplicationShutdown(_signal?: string): Promise<void> {
    this.stopping ??= this.shutdown();
    return this.stopping;
  }

  private get queues(): readonly Queue[] {
    return [this.notifications, this.media, this.maintenance];
  }

  private async shutdown(): Promise<void> {
    this.readiness.markStopping();
    if (this.keepAlive !== undefined) {
      clearInterval(this.keepAlive);
      this.keepAlive = undefined;
    }
    await Promise.all(this.queues.map((queue) => queue.close()));
    await this.redis.onApplicationShutdown();
    await this.postgres.onApplicationShutdown();
  }
}
