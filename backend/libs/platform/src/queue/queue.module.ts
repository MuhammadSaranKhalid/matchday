import { BullModule } from '@nestjs/bullmq';
import { Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

import type { PlatformConfiguration } from '../config/configuration.js';
import {
  buildQueueDefaultJobOptions,
  buildQueuePrefix,
  buildQueueProducerConnectionOptions,
  buildQueueWorkerConnectionOptions,
} from './queue-defaults.js';

@Module({
  imports: [
    BullModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (configuration: ConfigService<PlatformConfiguration, true>) => {
        const redis = configuration.get('redis', { infer: true });
        return {
          connection: buildQueueProducerConnectionOptions(redis),
          prefix: buildQueuePrefix(redis),
          defaultJobOptions: buildQueueDefaultJobOptions(
            configuration.get('queue', { infer: true }),
          ),
        };
      },
    }),
  ],
  exports: [BullModule],
})
export class QueueProducerModule {}

@Module({
  imports: [
    BullModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (configuration: ConfigService<PlatformConfiguration, true>) => {
        const redis = configuration.get('redis', { infer: true });
        return {
          connection: buildQueueWorkerConnectionOptions(redis),
          prefix: buildQueuePrefix(redis),
          defaultJobOptions: buildQueueDefaultJobOptions(
            configuration.get('queue', { infer: true }),
          ),
        };
      },
    }),
  ],
  exports: [BullModule],
})
export class QueueWorkerModule {}

export { QueueProducerModule as QueueModule };
