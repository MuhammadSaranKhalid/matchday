import { Injectable } from '@nestjs/common';
import type { QueryExecutor, TransactionPrincipal, TransactionWork } from './database.types.js';

interface ClientProvider {
  connect(): Promise<QueryExecutor & { release(): void }>;
}

@Injectable()
export class DatabaseExecutorService {
  constructor(private readonly pool: ClientProvider) {}

  withUserTransaction<T>(principal: TransactionPrincipal, work: TransactionWork<T>): Promise<T> {
    return this.transaction(async (database) => {
      await database.query("select set_config('role', $1, true)", [principal.role]);
      await database.query("select set_config('request.jwt.claims', $1, true)", [
        JSON.stringify({
          sub: principal.userId,
          role: principal.role,
          ...(principal.sessionId === undefined ? {} : { session_id: principal.sessionId }),
          app_metadata: principal.appMetadata,
        }),
      ]);
      return work(database);
    });
  }

  withSystemTransaction<T>(work: TransactionWork<T>): Promise<T> {
    return this.transaction(work);
  }

  private async transaction<T>(work: TransactionWork<T>): Promise<T> {
    const client = await this.pool.connect();
    try {
      await client.query('BEGIN');
      const result = await work(client);
      await client.query('COMMIT');
      return result;
    } catch (error) {
      try {
        await client.query('ROLLBACK');
      } catch {
        // Preserve the original transaction failure.
      }
      throw error;
    } finally {
      client.release();
    }
  }
}
