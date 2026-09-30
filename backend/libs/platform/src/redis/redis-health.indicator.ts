import { Injectable } from '@nestjs/common';
import { HealthIndicatorService, type HealthIndicatorResult } from '@nestjs/terminus';
import type { Redis } from 'ioredis';

interface RedisProvider {
  readonly command: Pick<Redis, 'status' | 'connect' | 'ping'>;
}

@Injectable()
export class RedisHealthIndicator {
  constructor(
    private readonly connections: RedisProvider,
    private readonly healthIndicator = new HealthIndicatorService(),
  ) {}

  async isHealthy(key: string): Promise<HealthIndicatorResult> {
    return await this.healthIndicator
      .check(key)
      .attempt(async () => {
        try {
          if (['wait', 'end'].includes(this.connections.command.status)) {
            await this.connections.command.connect();
          }
          const response = await this.connections.command.ping();
          if (response !== 'PONG') {
            throw new Error('Redis ping did not return PONG');
          }
        } catch {
          throw new Error('Redis connection failed');
        }
      })
      .withTimeout(1000);
  }
}
