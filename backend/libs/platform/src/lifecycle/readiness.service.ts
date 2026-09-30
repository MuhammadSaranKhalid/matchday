import { Injectable, type BeforeApplicationShutdown } from '@nestjs/common';

export type ReadinessState = 'starting' | 'ready' | 'stopping';

@Injectable()
export class ReadinessService implements BeforeApplicationShutdown {
  private state: ReadinessState = 'starting';

  isReady(): boolean {
    return this.state === 'ready';
  }

  markReady(): void {
    if (this.state !== 'stopping') {
      this.state = 'ready';
    }
  }

  markStopping(): void {
    this.state = 'stopping';
  }

  beforeApplicationShutdown(): void {
    this.markStopping();
  }
}
