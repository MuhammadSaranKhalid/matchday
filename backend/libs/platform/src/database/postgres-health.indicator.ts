import { Injectable } from '@nestjs/common';
import { HealthIndicatorService, type HealthIndicatorResult } from '@nestjs/terminus';

import type { QueryExecutor } from './database.types.js';

@Injectable()
export class PostgresHealthIndicator {
  constructor(
    private readonly database: QueryExecutor,
    private readonly healthIndicator = new HealthIndicatorService(),
  ) {}

  async isHealthy(key: string): Promise<HealthIndicatorResult> {
    return await this.healthIndicator
      .check(key)
      .attempt(async () => {
        try {
          await this.database.query('select 1');
        } catch {
          throw new Error('database query failed');
        }
      })
      .withTimeout(1000);
  }
}
