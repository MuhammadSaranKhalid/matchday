import 'reflect-metadata';

import type { INestApplicationContext } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { Logger } from 'nestjs-pino';

import { WorkerModule } from './worker.module.js';

export async function bootstrapWorker(): Promise<INestApplicationContext> {
  const app = await NestFactory.createApplicationContext(WorkerModule, {
    bufferLogs: true,
  });
  app.useLogger(app.get(Logger));
  app.flushLogs();
  app.enableShutdownHooks(['SIGTERM', 'SIGINT']);
  return app;
}

if (import.meta.url === `file://${process.argv[1]}`) {
  void bootstrapWorker();
}
