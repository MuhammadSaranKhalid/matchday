import { describe, expect, it, vi } from 'vitest';

import { PostgresHealthIndicator } from '../../../../libs/platform/src/database/postgres-health.indicator.js';

describe('PostgresHealthIndicator', () => {
  it('uses the minimal health query', async () => {
    const query = vi.fn(async () => ({ rows: [{ '?column?': 1 }], rowCount: 1 }));
    const indicator = new PostgresHealthIndicator({ query });
    await expect(indicator.isHealthy('postgres')).resolves.toMatchObject({ postgres: { status: 'up' } });
    expect(query).toHaveBeenCalledWith('select 1');
  });

  it('reports a sanitized down result', async () => {
    const indicator = new PostgresHealthIndicator({ query: vi.fn(async () => { throw new Error('secret'); }) });
    await expect(indicator.isHealthy('postgres')).resolves.toMatchObject({ postgres: { status: 'down' } });
  });
});
