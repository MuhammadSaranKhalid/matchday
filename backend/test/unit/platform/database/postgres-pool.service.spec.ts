import { afterEach, describe, expect, it, vi } from 'vitest';

const { poolConstructor, pool } = vi.hoisted(() => ({
  poolConstructor: vi.fn(),
  pool: { query: vi.fn(), connect: vi.fn(), end: vi.fn(async () => undefined) },
}));
vi.mock('pg', () => ({ Pool: class { constructor(options: unknown) { poolConstructor(options); return pool; } } }));

import { PostgresPoolService } from '../../../../libs/platform/src/database/postgres-pool.service.js';

describe('PostgresPoolService', () => {
  afterEach(() => vi.clearAllMocks());

  it('constructs one bounded pool and closes it once', async () => {
    const service = new PostgresPoolService({
      url: 'postgresql://user:secret@localhost/db', poolMax: 7, connectionTimeoutMs: 800,
      idleTimeoutMs: 900, statementTimeoutMs: 1_000, sslMode: 'verify-full',
    });
    expect(poolConstructor).toHaveBeenCalledOnce();
    expect(poolConstructor).toHaveBeenCalledWith(expect.objectContaining({
      connectionString: 'postgresql://user:secret@localhost/db', max: 7,
      connectionTimeoutMillis: 800, idleTimeoutMillis: 900, statement_timeout: 1_000,
      ssl: { rejectUnauthorized: true },
    }));
    await service.onApplicationShutdown();
    await service.onApplicationShutdown();
    expect(pool.end).toHaveBeenCalledOnce();
  });

  it('wraps driver errors without exposing connection credentials', async () => {
    pool.query.mockRejectedValueOnce(new Error('postgresql://user:secret@localhost/db failed'));
    const service = new PostgresPoolService({
      url: 'postgresql://user:secret@localhost/db', poolMax: 1, connectionTimeoutMs: 100,
      idleTimeoutMs: 100, statementTimeoutMs: 100, sslMode: 'disable',
    });
    const error = await service.query('select 1').catch((caught: unknown) => caught);
    expect(String(error)).toContain('PostgreSQL operation failed');
    expect(String(error)).not.toContain('secret');
  });
});
