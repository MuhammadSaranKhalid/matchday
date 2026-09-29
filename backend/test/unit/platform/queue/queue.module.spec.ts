import { MODULE_METADATA } from '@nestjs/common/constants';
import { describe, expect, it } from 'vitest';

import { QueueModule } from '../../../../libs/platform/src/queue/queue.module.js';

describe('QueueModule', () => {
  it('provides only BullMQ connection root without application queues', () => {
    expect(Reflect.getMetadata(MODULE_METADATA.PROVIDERS, QueueModule) ?? []).toEqual([]);
    const imports = Reflect.getMetadata(MODULE_METADATA.IMPORTS, QueueModule) as unknown[];
    expect(imports).toHaveLength(1);
    expect(JSON.stringify(imports)).not.toMatch(/processor|repeat|schedule|flow/i);
  });
});
