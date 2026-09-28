import 'reflect-metadata';

import { NestFactory } from '@nestjs/core';
import { Logger } from 'nestjs-pino';

import { buildConfiguration } from '../../../libs/platform/src/config/configuration.js';
import { parseEnvironment } from '../../../libs/platform/src/config/environment.schema.js';
import { ReadinessService } from '../../../libs/platform/src/health/readiness.service.js';
import { ApiModule } from './api.module.js';
import { configureApi } from './bootstrap/api-bootstrap.js';

export async function bootstrapApi(): Promise<void> {
  const configuration = buildConfiguration(parseEnvironment(process.env));
  const app = await NestFactory.create(ApiModule, {
    bodyParser: false,
    bufferLogs: true,
  });
  await configureApi(app, configuration);
  app.useLogger(app.get(Logger));
  await app.listen(configuration.port);
  app.get(ReadinessService).markReady();
}

if (import.meta.url === `file://${process.argv[1]}`) {
  void bootstrapApi();
}
