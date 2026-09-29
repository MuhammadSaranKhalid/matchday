import { Injectable, type BeforeApplicationShutdown } from '@nestjs/common';

@Injectable()
export class ReadinessService implements BeforeApplicationShutdown {
  private initialized = false;
  private queuesInitialized = false;
  private stopping = false;

  isReady(): boolean {
    return this.initialized && this.queuesInitialized && !this.stopping;
  }

  markReady(): void {
    if (!this.stopping) this.initialized = true;
  }

  markQueuesInitialized(): void {
    if (!this.stopping) this.queuesInitialized = true;
  }

  markStopping(): void {
    this.stopping = true;
    this.initialized = false;
    this.queuesInitialized = false;
  }

  beforeApplicationShutdown(): void {
    this.markStopping();
  }
}
