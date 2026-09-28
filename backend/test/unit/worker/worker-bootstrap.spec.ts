import type { INestApplicationContext } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { Logger } from 'nestjs-pino';
import { describe, expect, it, vi } from 'vitest';

import { bootstrapWorker } from '../../../apps/worker/src/main.js';
import { WorkerLifecycleService } from '../../../apps/worker/src/worker-lifecycle.service.js';
import { WorkerModule } from '../../../apps/worker/src/worker.module.js';
import { ReadinessService } from '../../../libs/platform/src/health/readiness.service.js';

describe('bootstrapWorker', () => {
  it('starts an application context with buffered logging and graceful shutdown', async () => {
    const logger = {} as Logger;
    const listen = vi.fn();
    const application = {
      enableShutdownHooks: vi.fn(),
      flushLogs: vi.fn(),
      get: vi.fn().mockReturnValue(logger),
      listen,
      useLogger: vi.fn(),
    } as unknown as INestApplicationContext;
    vi.spyOn(NestFactory, 'createApplicationContext').mockResolvedValue(application);

    await expect(bootstrapWorker()).resolves.toBe(application);

    expect(NestFactory.createApplicationContext).toHaveBeenCalledWith(WorkerModule, {
      bufferLogs: true,
    });
    expect(application.useLogger).toHaveBeenCalledWith(logger);
    expect(application.flushLogs).toHaveBeenCalledOnce();
    expect(application.enableShutdownHooks).toHaveBeenCalledWith(['SIGTERM', 'SIGINT']);
    expect(listen).not.toHaveBeenCalled();
  });
});

describe('WorkerLifecycleService', () => {
  it('marks the worker ready after initialization and stopping before shutdown', () => {
    vi.useFakeTimers();
    const readiness = new ReadinessService();
    const lifecycle = new WorkerLifecycleService(readiness);

    lifecycle.onApplicationBootstrap();
    expect(readiness.isReady()).toBe(true);
    expect(vi.getTimerCount()).toBe(1);

    lifecycle.beforeApplicationShutdown('SIGTERM');
    expect(readiness.isReady()).toBe(false);
    expect(vi.getTimerCount()).toBe(0);
    vi.useRealTimers();
  });
});
