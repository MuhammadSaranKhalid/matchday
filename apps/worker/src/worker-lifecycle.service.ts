import {
  type BeforeApplicationShutdown,
  Injectable,
  type OnApplicationBootstrap,
} from '@nestjs/common';

import { ReadinessService } from '../../../libs/platform/src/health/readiness.service.js';

@Injectable()
export class WorkerLifecycleService
  implements OnApplicationBootstrap, BeforeApplicationShutdown
{
  constructor(private readonly readiness: ReadinessService) {}

  onApplicationBootstrap(): void {
    this.readiness.markReady();
  }

  beforeApplicationShutdown(_signal?: string): void {
    this.readiness.markStopping();
  }
}
