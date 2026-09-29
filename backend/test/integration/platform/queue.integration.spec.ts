import { execFile } from 'node:child_process';
import { promisify } from 'node:util';
import { Module } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { getQueueToken } from '@nestjs/bullmq';
import type { Queue } from 'bullmq';
import { afterAll, describe, expect, it } from 'vitest';

import { PlatformConfigModule } from '../../../libs/platform/src/config/platform-config.module.js';
import { QueueModule } from '../../../libs/platform/src/queue/queue.module.js';
import { QUEUE_NAMES } from '../../../libs/platform/src/queue/queue-names.js';

const run = promisify(execFile);
const composeProject = process.env.MATCHDAY_COMPOSE_PROJECT;
const composeFile = process.env.MATCHDAY_COMPOSE_FILE;
if (composeProject === undefined || composeFile === undefined) {
  throw new Error('Queue integration harness environment is required');
}

async function compose(...arguments_: string[]): Promise<void> {
  await run('docker', ['compose', '-p', composeProject, '-f', composeFile, ...arguments_]);
}

@Module({ imports: [PlatformConfigModule, QueueModule] })
class QueueTestModule {}

describe('BullMQ queue lifecycle', () => {
  let close: (() => Promise<void>) | undefined;

  afterAll(async () => close?.());

  it('resolves empty, ready queues and closes their managed connections', async () => {
    const application = await NestFactory.createApplicationContext(QueueTestModule, { logger: false });
    close = () => application.close();

    for (const name of QUEUE_NAMES) {
      const queue = application.get<Queue>(getQueueToken(name));
      await expect(queue.waitUntilReady()).resolves.toBeUndefined();
      await expect(queue.getJobCounts()).resolves.toMatchObject({
        active: 0,
        completed: 0,
        delayed: 0,
        failed: 0,
        waiting: 0,
      });
    }

    await application.close();
    close = undefined;
  });

  it('fails a new queue connection within the configured startup bound', async () => {
    await compose('stop', 'redis');
    const started = Date.now();
    let application: Awaited<ReturnType<typeof NestFactory.createApplicationContext>> | undefined;

    try {
      application = await NestFactory.createApplicationContext(QueueTestModule, { logger: false });
      const queue = application.get<Queue>(getQueueToken('media'));
      await expect(queue.waitUntilReady()).rejects.toThrow();
      expect(Date.now() - started).toBeLessThan(2_000);
    } finally {
      await application?.close();
      await compose('start', 'redis');
    }
  });
});
