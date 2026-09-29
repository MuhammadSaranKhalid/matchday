import 'reflect-metadata';

import type { INestApplicationContext } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { Logger } from 'nestjs-pino';

import { WorkerModule } from '@app/worker/worker.module.js';
import { WorkerLifecycleService } from '@app/worker/lifecycle/worker-lifecycle.service.js';

export async function bootstrapWorker(): Promise<INestApplicationContext> {
  const app = await NestFactory.createApplicationContext(WorkerModule, {
    bufferLogs: true,
  });
  app.useLogger(app.get(Logger));
  app.flushLogs();
  app.enableShutdownHooks(['SIGTERM', 'SIGINT']);
  try {
    await app.get(WorkerLifecycleService).initialize();
    return app;
  } catch (error) {
    await app.close();
    throw error;
  }
}

if (import.meta.url === `file://${process.argv[1]}`) {
  void bootstrapWorker();
}
