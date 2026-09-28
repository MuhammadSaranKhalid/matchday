import { MiddlewareConsumer, Module, type NestModule } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';

import { parseEnvironment } from '../../../libs/platform/src/config/environment.schema.js';
import { PlatformConfigModule } from '../../../libs/platform/src/config/platform-config.module.js';
import { RequestContextMiddleware } from '../../../libs/platform/src/context/request-context.middleware.js';
import { LoggingModule } from '../../../libs/platform/src/logging/logging.module.js';

@Module({
  imports: [
    PlatformConfigModule,
    LoggingModule,
    ThrottlerModule.forRootAsync({
      useFactory: () => {
        const environment = parseEnvironment(process.env);
        return [
          {
            ttl: environment.THROTTLE_TTL_MS,
            limit: environment.THROTTLE_LIMIT,
          },
        ];
      },
    }),
  ],
  providers: [{ provide: APP_GUARD, useClass: ThrottlerGuard }],
})
export class ApiModule implements NestModule {
  configure(consumer: MiddlewareConsumer): void {
    consumer.apply(RequestContextMiddleware).forRoutes('*');
  }
}
