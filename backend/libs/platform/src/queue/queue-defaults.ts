import type { ConnectionOptions, DefaultJobOptions } from 'bullmq';

import type { QueueConfiguration, RedisConfiguration } from '../config/configuration.js';

export function buildQueueDefaultJobOptions(
  configuration: Readonly<QueueConfiguration>,
): DefaultJobOptions {
  return {
    attempts: configuration.attempts,
    backoff: {
      type: 'exponential',
      delay: configuration.backoffDelayMs,
    },
    removeOnComplete: configuration.removeOnCompleteCount,
    removeOnFail: configuration.removeOnFailCount,
  };
}

export function buildQueuePrefix(configuration: Readonly<RedisConfiguration>): string {
  return `${configuration.namespace}:bull`;
}

export function buildQueueProducerConnectionOptions(
  configuration: Readonly<RedisConfiguration>,
): ConnectionOptions {
  return {
    url: configuration.url,
    connectTimeout: configuration.connectionTimeoutMs,
    commandTimeout: configuration.commandTimeoutMs,
    maxRetriesPerRequest: configuration.maxRetriesPerRequest,
    enableOfflineQueue: false,
    retryStrategy: (attempt) =>
      attempt > configuration.maxRetriesPerRequest
        ? null
        : Math.min(attempt * 100, configuration.connectionTimeoutMs),
  };
}

export function buildQueueWorkerConnectionOptions(
  configuration: Readonly<RedisConfiguration>,
): ConnectionOptions {
  return {
    url: configuration.url,
    connectTimeout: configuration.connectionTimeoutMs,
    maxRetriesPerRequest: null,
    enableOfflineQueue: true,
    retryStrategy: (attempt) => Math.min(attempt * 100, 3000),
  };
}

export const buildQueueConnectionOptions = buildQueueProducerConnectionOptions;
