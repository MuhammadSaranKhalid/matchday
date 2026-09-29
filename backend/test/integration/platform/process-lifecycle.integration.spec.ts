import { execFile } from 'node:child_process';
import { promisify } from 'node:util';
import { afterAll, describe, expect, it } from 'vitest';

import { bootstrapWorker } from '../../../apps/worker/src/main.js';
import { ReadinessService } from '../../../libs/platform/src/health/readiness.service.js';

const run = promisify(execFile);
const composeProject = process.env.MATCHDAY_COMPOSE_PROJECT;
const composeFile = process.env.MATCHDAY_COMPOSE_FILE;
if (composeProject === undefined || composeFile === undefined) {
  throw new Error('Process integration harness environment is required');
}

async function compose(...arguments_: string[]): Promise<void> {
  await run('docker', ['compose', '-p', composeProject, '-f', composeFile, ...arguments_]);
}

describe('worker process lifecycle', () => {
  afterAll(async () => compose('start', 'redis'));

  it('starts only after dependencies are healthy and closes within the grace period', async () => {
    const application = await bootstrapWorker();
    expect(application.get(ReadinessService).isReady()).toBe(true);

    const started = Date.now();
    await application.close();
    expect(Date.now() - started).toBeLessThan(15_000);
  });

  it('fails fast and closes partial resources when Redis is unavailable', async () => {
    await compose('stop', 'redis');
    const started = Date.now();
    await expect(bootstrapWorker()).rejects.toThrow('Worker infrastructure is unavailable');
    expect(Date.now() - started).toBeLessThan(3_000);
  });
});
