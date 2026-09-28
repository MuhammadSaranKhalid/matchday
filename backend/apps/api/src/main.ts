import 'reflect-metadata';

import { NestFactory } from '@nestjs/core';
import { Logger } from 'nestjs-pino';

import { ApiModule } from '@app/api/api.module.js';
import { configureApi } from '@app/api/bootstrap/api-bootstrap.js';
import { buildConfiguration } from '@platform/config/configuration.js';
import { parseEnvironment } from '@platform/config/environment.schema.js';
import { ReadinessService } from '@platform/health/readiness.service.js';

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
