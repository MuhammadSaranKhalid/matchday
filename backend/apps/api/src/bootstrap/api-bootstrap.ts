import {
  type INestApplication,
  RequestMethod,
  ValidationPipe,
  VersioningType,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { json, urlencoded, type Application } from 'express';
import helmet from 'helmet';

import type { PlatformConfiguration } from '../../../../libs/platform/src/config/configuration.js';
import { ExecutionContextService } from '../../../../libs/platform/src/context/execution-context.service.js';
import { RequestContextMiddleware } from '../../../../libs/platform/src/context/request-context.middleware.js';
import { HttpExceptionFilter } from '../../../../libs/platform/src/errors/http-exception.filter.js';

export async function configureApi(
  app: INestApplication,
  customConfig?: PlatformConfiguration,
): Promise<void> {
  const configService = app.get<ConfigService<PlatformConfiguration, true>>(ConfigService);
  const config = customConfig ?? {
    trustProxyHops: configService.get('trustProxyHops', { infer: true }),
    corsOrigins: configService.get('corsOrigins', { infer: true }),
    bodyLimit: configService.get('bodyLimit', { infer: true }),
    production: configService.get('production', { infer: true }),
    swaggerEnabled: configService.get('swaggerEnabled', { infer: true }),
  };

  const context = app.get(ExecutionContextService);
  const requestContext = app.get(RequestContextMiddleware);
  const express = app.getHttpAdapter().getInstance() as Application;

  express.set('trust proxy', config.trustProxyHops);
  app.use(requestContext.use.bind(requestContext));
  app.enableShutdownHooks();
  app.setGlobalPrefix('api', {
    exclude: [
      { path: 'health/live', method: RequestMethod.GET },
      { path: 'health/ready', method: RequestMethod.GET },
    ],
  });
  app.enableVersioning({ type: VersioningType.URI, defaultVersion: '1' });
  app.enableCors({
    credentials: true,
    origin: (
      origin: string | undefined,
      callback: (error: Error | null, allow?: boolean) => void,
    ) => {
      if (origin === undefined || config.corsOrigins.includes(origin)) {
        callback(null, true);
        return;
      }
      callback(null, false);
    },
  });
  app.use(helmet());
  app.use(json({ limit: config.bodyLimit }));
  app.use(urlencoded({ extended: true, limit: config.bodyLimit }));
  app.useGlobalPipes(
    new ValidationPipe({
      transform: true,
      whitelist: true,
      forbidNonWhitelisted: true,
    }),
  );
  app.useGlobalFilters(
    new HttpExceptionFilter(context, config.production),
  );

  if (config.swaggerEnabled) {
    const document = SwaggerModule.createDocument(
      app,
      new DocumentBuilder()
        .setTitle('Matchday API')
        .setVersion('1')
        .addBearerAuth()
        .build(),
    );
    SwaggerModule.setup('api/docs', app, document, {
      jsonDocumentUrl: 'api/docs-json',
    });
  }
}
