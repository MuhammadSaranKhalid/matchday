import { execFile } from 'node:child_process';
import { promisify } from 'node:util';
import { afterAll, describe, expect, it } from 'vitest';

import type { RedisConfiguration } from '../../../libs/platform/src/config/configuration.js';
import { RedisConnectionsService } from '../../../libs/platform/src/redis/redis-connections.service.js';
import { RedisHealthIndicator } from '../../../libs/platform/src/redis/redis-health.indicator.js';

const run = promisify(execFile);
const redisUrl = process.env.REDIS_URL;
const composeProject = process.env.MATCHDAY_COMPOSE_PROJECT;
const composeFile = process.env.MATCHDAY_COMPOSE_FILE;
if (redisUrl === undefined || composeProject === undefined || composeFile === undefined) {
  throw new Error('Redis integration harness environment is required');
}

const configuration: RedisConfiguration = {
  url: redisUrl, connectionTimeoutMs: 250, commandTimeoutMs: 250,
  maxRetriesPerRequest: 1, namespace: 'matchday:integration',
};
const connections = new RedisConnectionsService(configuration);
const health = new RedisHealthIndicator(connections);

async function compose(...arguments_: string[]) {
  await run('docker', ['compose', '-p', composeProject, '-f', composeFile, ...arguments_]);
}

async function waitForRedisHealth(): Promise<void> {
  const { stdout } = await run('docker', ['compose', '-p', composeProject, '-f', composeFile, 'ps', '-q', 'redis']);
  const containerId = stdout.trim();
  for (let attempt = 0; attempt < 50; attempt += 1) {
    const inspection = await run('docker', ['inspect', '--format', '{{.State.Health.Status}}', containerId]);
    if (inspection.stdout.trim() === 'healthy') return;
    await new Promise((resolve) => setTimeout(resolve, 100));
  }
  throw new Error('Redis did not become healthy');
}

describe('Redis connection lifecycle', () => {
  afterAll(async () => connections.onApplicationShutdown());

  it('supports PING and namespaced data through owned distinct clients', async () => {
    await expect(health.isHealthy('redis')).resolves.toEqual({ redis: { status: 'up' } });
    const duplicate = connections.duplicate('integration');
    await duplicate.connect();
    expect(duplicate).not.toBe(connections.command);
    const key = connections.key('probe');
    await connections.command.set(key, 'value');
    await expect(duplicate.get(key)).resolves.toBe('value');
    await connections.command.del(key);
  });

  it('fails within configured bounds and recovers after Redis restarts', async () => {
    await compose('stop', 'redis');
    const started = Date.now();
    await expect(health.isHealthy('redis')).resolves.toEqual({ redis: { status: 'down' } });
    expect(Date.now() - started).toBeLessThan(1_500);

    await compose('start', 'redis');
    await waitForRedisHealth();
    let result = await health.isHealthy('redis');
    for (let attempt = 0; attempt < 20 && result.redis?.status !== 'up'; attempt += 1) {
      await new Promise((resolve) => setTimeout(resolve, 100));
      result = await health.isHealthy('redis');
    }
    expect(result).toEqual({ redis: { status: 'up' } });
  });
});
