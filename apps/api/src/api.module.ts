import { MiddlewareConsumer, Module, type NestModule } from '@nestjs/common';

import { PlatformConfigModule } from '../../../libs/platform/src/config/platform-config.module.js';
import { RequestContextMiddleware } from '../../../libs/platform/src/context/request-context.middleware.js';
import { LoggingModule } from '../../../libs/platform/src/logging/logging.module.js';

@Module({
  imports: [PlatformConfigModule, LoggingModule],
})
export class ApiModule implements NestModule {
  configure(consumer: MiddlewareConsumer): void {
    consumer.apply(RequestContextMiddleware).forRoutes('*');
  }
}
