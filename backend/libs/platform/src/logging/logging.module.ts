import { Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { LoggerModule } from 'nestjs-pino';

import type { PlatformConfiguration } from '../config/configuration.js';
import { PlatformConfigModule } from '../config/platform-config.module.js';
import { ExecutionContextModule } from '../context/execution-context.module.js';
import { ExecutionContextService } from '../context/execution-context.service.js';
import { buildPinoOptions, sanitizeRequestUrl } from './logging.config.js';

@Module({
  imports: [
    PlatformConfigModule,
    ExecutionContextModule,
    LoggerModule.forRootAsync({
      imports: [ExecutionContextModule],
      inject: [ConfigService, ExecutionContextService],
      useFactory: (
        configService: ConfigService<PlatformConfiguration, true>,
        context: ExecutionContextService,
      ) => {
        const appName = configService.get('appName', { infer: true });
        const logLevel = configService.get('logLevel', { infer: true });
        const options = buildPinoOptions(
          { appName, logLevel } as PlatformConfiguration,
          context,
        );
        return {
          pinoHttp: {
            ...options,
            autoLogging: true,
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
          },
        };
      },
    }),
  ],
  exports: [LoggerModule, ExecutionContextModule],
})
export class LoggingModule {}
