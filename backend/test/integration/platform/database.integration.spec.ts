import { afterAll, beforeAll, describe, expect, it } from 'vitest';

import type { DatabaseConfiguration } from '../../../libs/platform/src/config/configuration.js';
import { DatabaseExecutorService } from '../../../libs/platform/src/database/database-executor.service.js';
import { PostgresPoolService } from '../../../libs/platform/src/database/postgres-pool.service.js';

const databaseUrl = process.env.DATABASE_URL;
if (databaseUrl === undefined) throw new Error('DATABASE_URL is required for database integration tests');

const configuration: DatabaseConfiguration = {
  url: databaseUrl,
  poolMax: 2,
  connectionTimeoutMs: 250,
  idleTimeoutMs: 1_000,
  statementTimeoutMs: 250,
  sslMode: 'disable',
};
const pool = new PostgresPoolService(configuration);
const database = new DatabaseExecutorService(pool);

describe('PostgreSQL transaction boundary', () => {
  beforeAll(async () => {
    await pool.query('create role authenticated');
    await pool.query('create table transaction_probe (value text not null)');
    await pool.query('grant insert, select on transaction_probe to authenticated');
  });

  afterAll(async () => pool.onApplicationShutdown());

  it('reuses the bounded pool under concurrency', async () => {
    let active = 0;
    let maximumActive = 0;
    await Promise.all(Array.from({ length: 8 }, (_, index) =>
      database.withSystemTransaction(async (executor) => {
        active += 1;
        maximumActive = Math.max(maximumActive, active);
        await executor.query('select pg_sleep(0.03), $1::integer', [index]);
        active -= 1;
      }),
    ));
    expect(maximumActive).toBe(2);
  });

  it('rolls back failed work without persisting writes', async () => {
    await expect(database.withSystemTransaction(async (executor) => {
      await executor.query("insert into transaction_probe (value) values ('rollback')");
      throw new Error('fail the transaction');
    })).rejects.toThrow('fail the transaction');
    const result = await pool.query<{ count: string }>("select count(*)::text as count from transaction_probe where value = 'rollback'");
    expect(result.rows[0]?.count).toBe('0');
  });

  it('keeps verified claims local to the user transaction', async () => {
    const inside = await database.withUserTransaction(
      { userId: '7c50bd47-dfaf-4ad0-97d8-10b9b908f7ac', role: 'authenticated', sessionId: 'session-1', appMetadata: { tier: 'test' } },
      async (executor) => executor.query<{ claims: string }>("select current_setting('request.jwt.claims', true) as claims"),
    );
    expect(JSON.parse(inside.rows[0]?.claims ?? '{}')).toMatchObject({
      sub: '7c50bd47-dfaf-4ad0-97d8-10b9b908f7ac', role: 'authenticated', session_id: 'session-1',
    });
    const next = await database.withSystemTransaction(async (executor) =>
      executor.query<{ claims: string | null }>("select current_setting('request.jwt.claims', true) as claims"),
    );
    expect(next.rows[0]?.claims ?? '').toBe('');
  });

  it('bounds statement and acquisition waits', async () => {
    const started = Date.now();
    await expect(database.withSystemTransaction(async (executor) => executor.query('select pg_sleep(2)')))
      .rejects.toThrow();
    expect(Date.now() - started).toBeLessThan(1_000);

    let releaseHolders: (() => void) | undefined;
    const hold = new Promise<void>((resolve) => { releaseHolders = resolve; });
    const holders = [1, 2].map(() => database.withSystemTransaction(async () => hold));
    await new Promise((resolve) => setTimeout(resolve, 50));
    const acquisitionStarted = Date.now();
    await expect(database.withSystemTransaction(async () => undefined)).rejects.toThrow('PostgreSQL operation failed');
    expect(Date.now() - acquisitionStarted).toBeLessThan(1_000);
    releaseHolders?.();
    await Promise.all(holders);
  });
});
