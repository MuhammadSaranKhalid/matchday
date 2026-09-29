import { BullModule } from '@nestjs/bullmq';
import { Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

import type { PlatformConfiguration } from '../config/configuration.js';
import {
  buildQueueConnectionOptions,
  buildQueueDefaultJobOptions,
  buildQueuePrefix,
} from './queue-defaults.js';
import { QUEUE_NAMES } from './queue-names.js';

@Module({
  imports: [
    BullModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (configuration: ConfigService<PlatformConfiguration, true>) => {
        const redis = configuration.get('redis', { infer: true });
        return {
          connection: buildQueueConnectionOptions(redis),
          prefix: buildQueuePrefix(redis),
          defaultJobOptions: buildQueueDefaultJobOptions(
            configuration.get('queue', { infer: true }),
          ),
        };
      },
    }),
    BullModule.registerQueue(
      ...QUEUE_NAMES.map((name) => ({ name, forceDisconnectOnShutdown: true })),
    ),
  ],
  providers: [],
  exports: [BullModule],
})
export class QueueModule {}
