import 'reflect-metadata';

import { ConfigService } from '@nestjs/config';
import { NestFactory } from '@nestjs/core';
import type { NestExpressApplication } from '@nestjs/platform-express';
import { Logger } from 'nestjs-pino';

import { ApiModule } from '@app/api/api.module.js';
import { configureApi } from '@app/api/bootstrap/api-bootstrap.js';
import type { PlatformConfiguration } from '@platform/config/configuration.js';
import { ReadinessService } from '@platform/lifecycle/readiness.service.js';

export async function bootstrapApi(): Promise<void> {
  const app = await NestFactory.create<NestExpressApplication>(ApiModule, {
    bodyParser: false,
    bufferLogs: true,
    routeConflictPolicy: { duplicate: 'error', shadow: 'warn' },
    routeResolutionStrategy: 'specificity',
  });
  await configureApi(app);
  app.useLogger(app.get(Logger));
  const configService = app.get<ConfigService<PlatformConfiguration, true>>(ConfigService);
  const port = configService.get('port', { infer: true });
  await app.listen(port);
  const readiness = app.get(ReadinessService);
  readiness.markReady();
}

if (import.meta.url === `file://${process.argv[1]}`) {
  void bootstrapApi();
}
