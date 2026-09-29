import { Injectable } from '@nestjs/common';
import type { HealthIndicatorResult } from '@nestjs/terminus';
import type { Redis } from 'ioredis';

interface RedisProvider {
  readonly command: Pick<Redis, 'status' | 'connect' | 'ping'>;
}

@Injectable()
export class RedisHealthIndicator {
  constructor(private readonly connections: RedisProvider) {}

  async isHealthy(key: string): Promise<HealthIndicatorResult> {
    try {
      if (['wait', 'end'].includes(this.connections.command.status)) {
        await this.connections.command.connect();
      }
      const response = await this.connections.command.ping();
      return { [key]: { status: response === 'PONG' ? 'up' : 'down' } };
    } catch {
      return { [key]: { status: 'down' } };
    }
  }
}
