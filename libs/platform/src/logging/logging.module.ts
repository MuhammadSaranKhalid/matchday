import { Module } from '@nestjs/common';
import { LoggerModule } from 'nestjs-pino';

import { buildConfiguration } from '../config/configuration.js';
import { parseEnvironment } from '../config/environment.schema.js';
import { PlatformConfigModule } from '../config/platform-config.module.js';
import { ExecutionContextModule } from '../context/execution-context.module.js';
import { ExecutionContextService } from '../context/execution-context.service.js';
import { buildPinoOptions } from './logging.config.js';

@Module({
  imports: [
    PlatformConfigModule,
    ExecutionContextModule,
    LoggerModule.forRootAsync({
      imports: [ExecutionContextModule],
      inject: [ExecutionContextService],
      useFactory: (context: ExecutionContextService) => {
        const configuration = buildConfiguration(parseEnvironment(process.env));
        const options = buildPinoOptions(configuration, context);
        return {
          pinoHttp: {
            ...options,
            autoLogging: true,
            customProps: () => context.get(),
            serializers: {
              req: (request: { id?: string; method?: string; url?: string }) => ({
                id: request.id,
                method: request.method,
                url: request.url,
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
