import { describe, expect, it, vi } from 'vitest';

import { RedisHealthIndicator } from '../../../../libs/platform/src/redis/redis-health.indicator.js';

describe('RedisHealthIndicator', () => {
  it('connects lazily and checks PING', async () => {
    const client = { status: 'wait', connect: vi.fn(async () => undefined), ping: vi.fn(async () => 'PONG') };
    const indicator = new RedisHealthIndicator({ command: client });
    await expect(indicator.isHealthy('redis')).resolves.toEqual({ redis: { status: 'up' } });
    expect(client.connect).toHaveBeenCalledOnce();
    expect(client.ping).toHaveBeenCalledOnce();
  });

  it('returns a sanitized down result on failure', async () => {
    const client = { status: 'ready', connect: vi.fn(), ping: vi.fn(async () => { throw new Error('redis://:secret@host'); }) };
    const indicator = new RedisHealthIndicator({ command: client });
    await expect(indicator.isHealthy('redis')).resolves.toEqual({ redis: { status: 'down' } });
  });

  it('reconnects a client whose bounded retry cycle reached end', async () => {
    const client = { status: 'end', connect: vi.fn(async () => undefined), ping: vi.fn(async () => 'PONG') };
    const indicator = new RedisHealthIndicator({ command: client });
    await expect(indicator.isHealthy('redis')).resolves.toEqual({ redis: { status: 'up' } });
    expect(client.connect).toHaveBeenCalledOnce();
  });
});
