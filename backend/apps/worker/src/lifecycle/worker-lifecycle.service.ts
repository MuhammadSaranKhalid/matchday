import {
  type BeforeApplicationShutdown,
  Inject,
  Injectable,
} from '@nestjs/common';

import {
  MEDIA_QUEUE_READINESS,
  type MediaQueueReadiness,
} from '@modules/media';
import { PostgresHealthIndicator } from '../../../../libs/platform/src/database/postgres-health.indicator.js';
import { ReadinessService } from '../../../../libs/platform/src/lifecycle/readiness.service.js';

@Injectable()
export class WorkerLifecycleService
  implements BeforeApplicationShutdown
{
  constructor(
    private readonly readiness: ReadinessService,
    private readonly postgresHealth: PostgresHealthIndicator,
    @Inject(MEDIA_QUEUE_READINESS) private readonly queueReadiness: MediaQueueReadiness,
  ) {}

  async initialize(): Promise<void> {
    try {
      const [postgres] = await Promise.all([
        this.postgresHealth.isHealthy('postgres'),
        this.queueReadiness.waitUntilReady(),
      ]);
      if (postgres.postgres?.status !== 'up') {
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
