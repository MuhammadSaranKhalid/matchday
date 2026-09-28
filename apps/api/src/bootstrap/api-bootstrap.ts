import {
  type INestApplication,
  RequestMethod,
  ValidationPipe,
  VersioningType,
} from '@nestjs/common';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { json, urlencoded, type Application } from 'express';
import helmet from 'helmet';
import { Logger as PinoLogger } from 'nestjs-pino';
import { pinoHttp } from 'pino-http';

import type { PlatformConfiguration } from '../../../../libs/platform/src/config/configuration.js';
import { ExecutionContextService } from '../../../../libs/platform/src/context/execution-context.service.js';
import { RequestContextMiddleware } from '../../../../libs/platform/src/context/request-context.middleware.js';
import { HttpExceptionFilter } from '../../../../libs/platform/src/errors/http-exception.filter.js';
import {
  buildPinoOptions,
  sanitizeRequestUrl,
} from '../../../../libs/platform/src/logging/logging.config.js';

export async function configureApi(
  app: INestApplication,
  config: PlatformConfiguration,
): Promise<void> {
  const context = app.get(ExecutionContextService);
  const requestContext = new RequestContextMiddleware(context);
  const express = app.getHttpAdapter().getInstance() as Application;

  express.set('trust proxy', config.trustProxyHops);
  app.use(requestContext.use.bind(requestContext));
  app.use(
    pinoHttp({
      ...buildPinoOptions(config, context),
      serializers: {
        req: (request: { id?: string; method?: string; url?: string }) => ({
          id: request.id,
          method: request.method,
          url: sanitizeRequestUrl(request.url),
        }),
        res: (response: { statusCode?: number }) => ({
          statusCode: response.statusCode,
        }),
      },
    }),
  );
  app.useLogger(app.get(PinoLogger));
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
