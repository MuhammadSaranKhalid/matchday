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
  private keepAlive: ReturnType<typeof setInterval> | undefined;

  constructor(private readonly readiness: ReadinessService) {}

  onApplicationBootstrap(): void {
    this.keepAlive ??= setInterval(() => undefined, 60_000);
    this.readiness.markReady();
  }

  beforeApplicationShutdown(_signal?: string): void {
    this.readiness.markStopping();
    if (this.keepAlive !== undefined) {
      clearInterval(this.keepAlive);
      this.keepAlive = undefined;
    }
  }
}
