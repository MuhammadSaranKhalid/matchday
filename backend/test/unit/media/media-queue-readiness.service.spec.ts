import type { Queue } from 'bullmq';
import { describe, expect, it, vi } from 'vitest';

import { BullMqMediaQueueReadinessService } from '../../../libs/modules/media/src/infrastructure/queue/bullmq-media-queue-readiness.service.js';

describe('BullMqMediaQueueReadinessService', () => {
  it('delegates waitUntilReady to the injected queue', async () => {
    const queue = {
      waitUntilReady: vi.fn().mockResolvedValue(undefined),
    } as unknown as Queue;
    const readiness = new BullMqMediaQueueReadinessService(queue);

    await expect(readiness.waitUntilReady()).resolves.toBeUndefined();
    expect(queue.waitUntilReady).toHaveBeenCalledOnce();
  });

  it('propagates readiness failures', async () => {
    const failure = new Error('redis connection refused');
    const queue = {
      waitUntilReady: vi.fn().mockRejectedValue(failure),
    } as unknown as Queue;
    const readiness = new BullMqMediaQueueReadinessService(queue);

    await expect(readiness.waitUntilReady()).rejects.toThrow('redis connection refused');
  });
});
