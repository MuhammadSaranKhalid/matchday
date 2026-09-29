import { Module } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';

import { parseEnvironment } from '../../../libs/platform/src/config/environment.schema.js';
import { PlatformConfigModule } from '../../../libs/platform/src/config/platform-config.module.js';
import { AuthModule } from '../../../libs/platform/src/auth/auth.module.js';
import { QueueModule } from '../../../libs/platform/src/queue/queue.module.js';
import { HealthModule } from '../../../libs/platform/src/health/health.module.js';
import { LoggingModule } from '../../../libs/platform/src/logging/logging.module.js';

@Module({
  imports: [
    PlatformConfigModule,
    LoggingModule,
    AuthModule,
    QueueModule,
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
