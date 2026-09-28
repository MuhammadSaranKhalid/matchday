import { Injectable, type BeforeApplicationShutdown } from '@nestjs/common';

@Injectable()
export class ReadinessService implements BeforeApplicationShutdown {
  private ready = false;
  private stopping = false;

  isReady(): boolean {
    return this.ready && !this.stopping;
  }

  markReady(): void {
    if (!this.stopping) this.ready = true;
  }

  markStopping(): void {
    this.stopping = true;
    this.ready = false;
  }

  beforeApplicationShutdown(): void {
    this.markStopping();
  }
}
