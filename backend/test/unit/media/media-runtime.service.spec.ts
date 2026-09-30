import type { Queue } from 'bullmq';
import { describe, expect, it, vi } from 'vitest';

import { BullMqMediaRuntimeService } from '../../../libs/modules/media/src/infrastructure/queue/bullmq-media-runtime.service.js';

describe('BullMqMediaRuntimeService', () => {
  it('delegates waitUntilReady to the injected queue', async () => {
    const queue = {
      waitUntilReady: vi.fn().mockResolvedValue(undefined),
    } as unknown as Queue;
    const runtime = new BullMqMediaRuntimeService(queue);

    await expect(runtime.waitUntilReady()).resolves.toBeUndefined();
    expect(queue.waitUntilReady).toHaveBeenCalledOnce();
  });

  it('propagates readiness failures', async () => {
    const failure = new Error('redis connection refused');
    const queue = {
      waitUntilReady: vi.fn().mockRejectedValue(failure),
    } as unknown as Queue;
    const runtime = new BullMqMediaRuntimeService(queue);

    await expect(runtime.waitUntilReady()).rejects.toThrow('redis connection refused');
  });
});
