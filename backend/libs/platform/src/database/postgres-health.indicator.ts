import { Injectable } from '@nestjs/common';
import type { HealthIndicatorResult } from '@nestjs/terminus';

import type { QueryExecutor } from './database.types.js';

@Injectable()
export class PostgresHealthIndicator {
  constructor(private readonly database: QueryExecutor) {}

  async isHealthy(key: string): Promise<HealthIndicatorResult> {
    try {
      await this.database.query('select 1');
      return { [key]: { status: 'up' } };
    } catch {
      return { [key]: { status: 'down' } };
    }
  }
}
