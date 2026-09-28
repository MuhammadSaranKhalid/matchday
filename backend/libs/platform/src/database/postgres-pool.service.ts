import { Injectable, type OnApplicationShutdown } from '@nestjs/common';
import { Pool, type PoolClient, type QueryConfig, type QueryResult, type QueryResultRow } from 'pg';

import type { DatabaseConfiguration } from '../config/configuration.js';
import type { QueryExecutor } from './database.types.js';

@Injectable()
export class PostgresPoolService implements QueryExecutor, OnApplicationShutdown {
  private readonly pool: Pool;
  private closing?: Promise<void>;

  constructor(configuration: Readonly<DatabaseConfiguration>) {
    this.pool = new Pool({
      connectionString: configuration.url,
      max: configuration.poolMax,
      connectionTimeoutMillis: configuration.connectionTimeoutMs,
      idleTimeoutMillis: configuration.idleTimeoutMs,
      statement_timeout: configuration.statementTimeoutMs,
      ssl: sslConfiguration(configuration.sslMode),
    });
  }

  async query<T extends QueryResultRow = QueryResultRow>(
    queryTextOrConfig: string | QueryConfig,
    values?: readonly unknown[],
  ): Promise<QueryResult<T>> {
    try {
      return await this.pool.query<T>(queryTextOrConfig, values as unknown[] | undefined);
    } catch (error) {
      throw sanitizedDatabaseError(error);
    }
  }

  async connect(): Promise<PoolClient> {
    try {
      return await this.pool.connect();
    } catch (error) {
      throw sanitizedDatabaseError(error);
    }
  }

  onApplicationShutdown(): Promise<void> {
    this.closing ??= this.pool.end();
    return this.closing;
  }
}

function sslConfiguration(mode: DatabaseConfiguration['sslMode']): false | { rejectUnauthorized: boolean } {
  if (mode === 'disable') return false;
  return { rejectUnauthorized: mode === 'verify-full' };
}

function sanitizedDatabaseError(error: unknown): Error {
  return new Error('PostgreSQL operation failed', { cause: error });
}
