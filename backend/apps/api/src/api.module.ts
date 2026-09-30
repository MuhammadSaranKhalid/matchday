import { Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { APP_GUARD } from '@nestjs/core';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';

import type { PlatformConfiguration } from '../../../libs/platform/src/config/configuration.js';
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
      inject: [ConfigService],
      useFactory: (configuration: ConfigService<PlatformConfiguration, true>) => {
        const throttle = configuration.get('throttle', { infer: true });
        return [
          {
            ttl: throttle.ttlMs,
            limit: throttle.limit,
          },
        ];
      },
    }),
  ],
  providers: [{ provide: APP_GUARD, useClass: ThrottlerGuard }],
})
export class ApiModule {}
