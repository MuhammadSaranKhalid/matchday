import { MODULE_METADATA } from '@nestjs/common/constants';
import { describe, expect, it } from 'vitest';

import {
  QueueModule,
  QueueProducerModule,
  QueueWorkerModule,
} from '../../../../libs/platform/src/queue/queue.module.js';

describe('Queue modules', () => {
  it('provides only BullMQ connection root without application queues for producer', () => {
    expect(Reflect.getMetadata(MODULE_METADATA.PROVIDERS, QueueProducerModule) ?? []).toEqual([]);
    const imports = Reflect.getMetadata(MODULE_METADATA.IMPORTS, QueueProducerModule) as unknown[];
    expect(imports).toHaveLength(1);
    expect(JSON.stringify(imports)).not.toMatch(/processor|repeat|schedule|flow/i);
    expect(QueueModule).toBe(QueueProducerModule);
  });

  it('provides only BullMQ connection root without application queues for worker', () => {
    expect(Reflect.getMetadata(MODULE_METADATA.PROVIDERS, QueueWorkerModule) ?? []).toEqual([]);
    const imports = Reflect.getMetadata(MODULE_METADATA.IMPORTS, QueueWorkerModule) as unknown[];
    expect(imports).toHaveLength(1);
    expect(JSON.stringify(imports)).not.toMatch(/processor|repeat|schedule|flow/i);
  });
});
