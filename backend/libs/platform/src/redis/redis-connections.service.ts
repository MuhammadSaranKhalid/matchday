import { Injectable, type OnApplicationShutdown } from '@nestjs/common';
import { Redis, type RedisOptions } from 'ioredis';

import type { RedisConfiguration } from '../config/configuration.js';
import type { RedisConnections } from './redis.types.js';

type RedisFactory = (url: string, options: RedisOptions) => Redis;

@Injectable()
export class RedisConnectionsService implements RedisConnections, OnApplicationShutdown {
  readonly command: Redis;
  private readonly owned = new Map<string, Redis>();
  private closing?: Promise<void>;

  constructor(
    private readonly configuration: Readonly<RedisConfiguration>,
    private readonly factory: RedisFactory = (url, options) => new Redis(url, options),
  ) {
    this.command = this.create('command');
  }

  duplicate(purpose: string): Redis {
    if (!/^[a-z0-9:_-]+$/.test(purpose)) throw new Error('Invalid Redis connection purpose');
    const identifier = `${purpose}:${this.owned.size}`;
    return this.create(identifier);
  }

  key(unqualifiedKey: string): string {
    if (unqualifiedKey.length === 0 || unqualifiedKey.startsWith(':')) {
      throw new Error('Invalid Redis key');
    }
    return `${this.configuration.namespace}:${unqualifiedKey}`;
  }

  onApplicationShutdown(): Promise<void> {
    this.closing ??= this.closeAll();
    return this.closing;
  }

  private create(identifier: string): Redis {
    const client = this.factory(this.configuration.url, {
      lazyConnect: true,
      connectTimeout: this.configuration.connectionTimeoutMs,
      commandTimeout: this.configuration.commandTimeoutMs,
      maxRetriesPerRequest: this.configuration.maxRetriesPerRequest,
      enableOfflineQueue: false,
      retryStrategy: (attempt) => Math.min(attempt * 100, this.configuration.connectionTimeoutMs),
    });
    client.on('error', () => undefined);
    this.owned.set(identifier, client);
    return client;
  }

  private async closeAll(): Promise<void> {
    await Promise.all([...this.owned.values()].map(async (client) => {
      if (['ready', 'connect', 'connecting'].includes(client.status)) {
        try {
          await client.quit();
          return;
        } catch {
          // Force-close a partially failed connection below.
        }
      }
      client.disconnect(false);
    }));
  }
}
