import { Module } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';

import { parseEnvironment } from '../../../libs/platform/src/config/environment.schema.js';
import { PlatformConfigModule } from '../../../libs/platform/src/config/platform-config.module.js';
import { HealthModule } from '../../../libs/platform/src/health/health.module.js';
import { LoggingModule } from '../../../libs/platform/src/logging/logging.module.js';
import { PostsModule } from '@modules/posts';

@Module({
  imports: [
    PlatformConfigModule,
    LoggingModule,
    PostsModule,
    HealthModule,
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
export class ApiModule {}
