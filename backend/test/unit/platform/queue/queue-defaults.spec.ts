import { describe, expect, it } from 'vitest';

import type { QueueConfiguration, RedisConfiguration } from '../../../../libs/platform/src/config/configuration.js';
import {
  buildQueueConnectionOptions,
  buildQueueDefaultJobOptions,
  buildQueuePrefix,
} from '../../../../libs/platform/src/queue/queue-defaults.js';

const queue: QueueConfiguration = {
  attempts: 5,
  backoffDelayMs: 1_000,
  removeOnCompleteCount: 250,
  removeOnFailCount: 500,
};

const redis: RedisConfiguration = {
  url: 'rediss://worker:secret@redis.example:6380/2',
  connectionTimeoutMs: 800,
  commandTimeoutMs: 600,
  maxRetriesPerRequest: 3,
  namespace: 'matchday:test',
};

describe('queue defaults', () => {
  it('builds bounded exponential retry and retention defaults', () => {
    expect(buildQueueDefaultJobOptions(queue)).toEqual({
      attempts: 5,
      backoff: { type: 'exponential', delay: 1_000 },
      removeOnComplete: 250,
      removeOnFail: 500,
    });
  });

  it('uses a namespaced BullMQ prefix without embedding a key prefix in ioredis', () => {
    expect(buildQueuePrefix(redis)).toBe('matchday:test:bull');
    expect(buildQueueConnectionOptions(redis)).toMatchObject({
      url: redis.url,
      connectTimeout: 800,
      commandTimeout: 600,
      maxRetriesPerRequest: 3,
      enableOfflineQueue: false,
    });
    expect(buildQueueConnectionOptions(redis)).not.toHaveProperty('keyPrefix');
  });

  it('bounds connection retry during startup', () => {
    const options = buildQueueConnectionOptions(redis);
    expect(options.retryStrategy?.(1)).toBe(100);
    expect(options.retryStrategy?.(3)).toBe(300);
    expect(options.retryStrategy?.(4)).toBeNull();
  });
});
