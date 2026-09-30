import { describe, expect, it, vi } from 'vitest';

import { DatabaseExecutorService } from '../../../../libs/platform/src/database/database-executor.service.js';

function clientFixture() {
  const calls: Array<{ sql: string; values?: readonly unknown[] }> = [];
  const client = {
    query: vi.fn(async (sql: string, values?: readonly unknown[]) => {
      calls.push({ sql, ...(values === undefined ? {} : { values }) });
      return { rows: [], rowCount: 0 };
    }),
    release: vi.fn(),
  };
  return { client, calls };
}

describe('DatabaseExecutorService', () => {
  it('sets parameterized transaction-local identity before user work and commits', async () => {
    const { client, calls } = clientFixture();
    const service = new DatabaseExecutorService({ connect: vi.fn(async () => client) });
    const result = await service.withUserTransaction(
      { userId: '7c50bd47-dfaf-4ad0-97d8-10b9b908f7ac', sessionId: 'session-1', appMetadata: { plan: 'pro' } },
      async (database) => {
        await database.query('select $1::text', ['work']);
        return 'result';
      },
    );

    expect(result).toBe('result');
    expect(calls).toEqual([
      { sql: 'BEGIN' },
      { sql: "select set_config('role', $1, true)", values: ['authenticated'] },
      {
        sql: "select set_config('request.jwt.claims', $1, true)",
        values: [JSON.stringify({ sub: '7c50bd47-dfaf-4ad0-97d8-10b9b908f7ac', role: 'authenticated', session_id: 'session-1', app_metadata: { plan: 'pro' } })],
      },
      { sql: 'select $1::text', values: ['work'] },
      { sql: 'COMMIT' },
    ]);
    expect(client.release).toHaveBeenCalledOnce();
  });

  it.each(['callback', 'setup'] as const)('rolls back and releases after %s failure', async (failurePoint) => {
    const { client, calls } = clientFixture();
    if (failurePoint === 'setup') client.query.mockRejectedValueOnce(new Error('setup failed'));
    const service = new DatabaseExecutorService({ connect: vi.fn(async () => client) });

    await expect(service.withUserTransaction(
      { userId: '7c50bd47-dfaf-4ad0-97d8-10b9b908f7ac', sessionId: 'session-1', appMetadata: {} },
      async () => { throw new Error('callback failed'); },
    )).rejects.toThrow(failurePoint === 'setup' ? 'setup failed' : 'callback failed');

    expect(calls.at(-1)?.sql).toBe('ROLLBACK');
    expect(client.release).toHaveBeenCalledOnce();
  });

  it('runs explicitly named system work without user claim setup', async () => {
    const { client, calls } = clientFixture();
    const service = new DatabaseExecutorService({ connect: vi.fn(async () => client) });
    await service.withSystemTransaction(async (database) => database.query('select 1'));
    expect(calls.map(({ sql }) => sql)).toEqual(['BEGIN', 'select 1', 'COMMIT']);
  });
});
