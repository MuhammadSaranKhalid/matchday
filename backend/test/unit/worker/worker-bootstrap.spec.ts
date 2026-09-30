import type { INestApplicationContext } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { Logger } from 'nestjs-pino';
import { describe, expect, it, vi } from 'vitest';

import { bootstrapWorker } from '../../../apps/worker/src/main.js';
import { WorkerLifecycleService } from '../../../apps/worker/src/lifecycle/worker-lifecycle.service.js';
import { WorkerModule } from '../../../apps/worker/src/worker.module.js';
import { ReadinessService } from '../../../libs/platform/src/lifecycle/readiness.service.js';

describe('bootstrapWorker', () => {
  it('starts an application context with buffered logging and graceful shutdown', async () => {
    const logger = {} as Logger;
    const lifecycle = { initialize: vi.fn(async () => undefined) };
    const listen = vi.fn();
    const application = {
      enableShutdownHooks: vi.fn(),
      flushLogs: vi.fn(),
      get: vi.fn((token) => token === WorkerLifecycleService ? lifecycle : logger),
      listen,
      useLogger: vi.fn(),
      close: vi.fn(),
    } as unknown as INestApplicationContext;
    vi.spyOn(NestFactory, 'createApplicationContext').mockResolvedValue(application);

    await expect(bootstrapWorker()).resolves.toBe(application);

    expect(NestFactory.createApplicationContext).toHaveBeenCalledWith(WorkerModule, {
      bufferLogs: true,
    });
    expect(application.useLogger).toHaveBeenCalledWith(logger);
    expect(application.flushLogs).toHaveBeenCalledOnce();
    expect(application.enableShutdownHooks).toHaveBeenCalledWith(['SIGTERM', 'SIGINT']);
    expect(lifecycle.initialize).toHaveBeenCalledOnce();
    expect(listen).not.toHaveBeenCalled();
  });

  it('closes a partially initialized context when infrastructure startup fails', async () => {
    const failure = new Error('dependency unavailable');
    const lifecycle = { initialize: vi.fn(async () => { throw failure; }) };
    const application = {
      enableShutdownHooks: vi.fn(),
      flushLogs: vi.fn(),
      get: vi.fn((token) => token === WorkerLifecycleService ? lifecycle : {}),
      useLogger: vi.fn(),
      close: vi.fn(async () => undefined),
    } as unknown as INestApplicationContext;
    vi.spyOn(NestFactory, 'createApplicationContext').mockResolvedValue(application);

    await expect(bootstrapWorker()).rejects.toBe(failure);
    expect(application.close).toHaveBeenCalledOnce();
  });
});

describe('WorkerLifecycleService', () => {
  it('checks dependencies, marks ready, and sets stopping on shutdown', async () => {
    const readiness = new ReadinessService();
    const postgresHealth = { isHealthy: vi.fn(async () => ({ postgres: { status: 'up' } })) };
    const redisHealth = { isHealthy: vi.fn(async () => ({ redis: { status: 'up' } })) };
    const mediaRuntime = { waitUntilReady: vi.fn(async () => undefined) };
    const lifecycle = new WorkerLifecycleService(
      readiness,
      postgresHealth as never,
      redisHealth as never,
      mediaRuntime as never,
    );

    await lifecycle.initialize();
    expect(readiness.isReady()).toBe(true);
    expect(mediaRuntime.waitUntilReady).toHaveBeenCalledOnce();

    await lifecycle.beforeApplicationShutdown('SIGTERM');
    expect(readiness.isReady()).toBe(false);
  });

  it('fails initialization when dependencies are down', async () => {
    const readiness = new ReadinessService();
    const postgresHealth = { isHealthy: vi.fn(async () => ({ postgres: { status: 'down' } })) };
    const redisHealth = { isHealthy: vi.fn(async () => ({ redis: { status: 'up' } })) };
    const mediaRuntime = { waitUntilReady: vi.fn(async () => undefined) };
    const lifecycle = new WorkerLifecycleService(
      readiness,
      postgresHealth as never,
      redisHealth as never,
      mediaRuntime as never,
    );

    await expect(lifecycle.initialize()).rejects.toThrow('Worker infrastructure is unavailable');
    expect(readiness.isReady()).toBe(false);
  });
});
