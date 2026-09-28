import 'reflect-metadata';

import { NestFactory } from '@nestjs/core';

import { ApiModule } from './api.module.js';

export async function bootstrapApi(): Promise<void> {
  const app = await NestFactory.create(ApiModule);
  app.enableShutdownHooks();
  await app.listen(Number(process.env.PORT ?? 3000));
}

if (import.meta.url === `file://${process.argv[1]}`) {
  void bootstrapApi();
}
