import { describe, expect, it, vi } from 'vitest';

import type { RedisConfiguration } from '../../../../libs/platform/src/config/configuration.js';
import { RedisConnectionsService } from '../../../../libs/platform/src/redis/redis-connections.service.js';

const configuration: RedisConfiguration = {
  url: 'redis://default:secret@localhost:6379', connectionTimeoutMs: 700,
  commandTimeoutMs: 500, maxRetriesPerRequest: 2, namespace: 'matchday:test',
};

function fixture() {
  const clients: Array<{ status: string; quit: ReturnType<typeof vi.fn>; disconnect: ReturnType<typeof vi.fn> }> = [];
  const factory = vi.fn(() => {
    const client = { status: 'wait', on: vi.fn(), quit: vi.fn(async () => 'OK'), disconnect: vi.fn() };
    clients.push(client);
    return client;
  });
  return { service: new RedisConnectionsService(configuration, factory), factory, clients };
}

describe('RedisConnectionsService', () => {
  it('owns one lazily connected bounded command connection', () => {
    const { service, factory, clients } = fixture();
    expect(service.command).toBe(service.command);
    expect(factory).toHaveBeenCalledOnce();
    expect(factory).toHaveBeenCalledWith(configuration.url, expect.objectContaining({
      lazyConnect: true, connectTimeout: 700, commandTimeout: 500,
      maxRetriesPerRequest: 2, enableOfflineQueue: false,
    }));
    const options = factory.mock.calls[0]![1];
    expect(options.retryStrategy?.(1)).toBe(100);
    expect(options.retryStrategy?.(100)).toBe(700);
    expect(clients[0]!.on).toHaveBeenCalledWith('error', expect.any(Function));
    expect(service.key('probe')).toBe('matchday:test:probe');
  });

  it('owns distinct purpose duplicates and closes every client once', async () => {
    const { service, clients } = fixture();
    expect(service.duplicate('bullmq')).not.toBe(service.command);
    expect(service.duplicate('pubsub')).not.toBe(service.command);
    await service.onApplicationShutdown();
    await service.onApplicationShutdown();
    expect(clients).toHaveLength(3);
    for (const client of clients) expect(client.disconnect).toHaveBeenCalledOnce();
  });

  it('uses graceful quit for connected clients and disconnect after quit failure', async () => {
    const { service, clients } = fixture();
    void service.command;
    clients[0]!.status = 'ready';
    clients[0]!.quit.mockRejectedValueOnce(new Error(configuration.url));
    await expect(service.onApplicationShutdown()).resolves.toBeUndefined();
    expect(clients[0]!.quit).toHaveBeenCalledOnce();
    expect(clients[0]!.disconnect).toHaveBeenCalledOnce();
  });
});
