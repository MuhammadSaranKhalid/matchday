import { MODULE_METADATA } from '@nestjs/common/constants';
import { describe, expect, it } from 'vitest';

import { QueueModule } from '../../../../libs/platform/src/queue/queue.module.js';
import { QUEUE_NAMES } from '../../../../libs/platform/src/queue/queue-names.js';

describe('QueueModule', () => {
  it('defines only the three foundation queues', () => {
    expect(QUEUE_NAMES).toEqual(['notifications', 'media', 'maintenance']);
    expect(Object.isFrozen(QUEUE_NAMES)).toBe(true);
  });

  it('does not register processors, schedules, or application providers', () => {
    expect(Reflect.getMetadata(MODULE_METADATA.PROVIDERS, QueueModule) ?? []).toEqual([]);
    const imports = Reflect.getMetadata(MODULE_METADATA.IMPORTS, QueueModule) as unknown[];
    expect(imports).toHaveLength(2);
    expect(JSON.stringify(imports)).not.toMatch(/processor|repeat|schedule|flow/i);
  });
});
