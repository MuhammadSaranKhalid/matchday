import { describe, expect, it, vi } from 'vitest';

import { BullMqMediaJobProducer } from '../../../libs/modules/media/src/infrastructure/queue/bullmq-media-job.producer.js';

describe('BullMqMediaJobProducer', () => {
  it('adds the V2 payload with deterministic generation job ID (default generation 1)', async () => {
    const queue = { add: vi.fn().mockResolvedValue({ id: 'media-job-id' }) };
    const producer = new BullMqMediaJobProducer(queue);

    await producer.enqueueImage('40000000-0000-4000-8000-000000000001');

    expect(queue.add).toHaveBeenCalledWith(
      'process-image',
      { schemaVersion: 2, mediaId: '40000000-0000-4000-8000-000000000001', generation: 1 },
      { jobId: 'media-40000000-0000-4000-8000-000000000001-g1' },
    );
  });

  it('adds the V2 payload with custom generation', async () => {
    const queue = { add: vi.fn().mockResolvedValue({ id: 'media-job-id' }) };
    const producer = new BullMqMediaJobProducer(queue);

    await producer.enqueueImage('40000000-0000-4000-8000-000000000001', 3);

    expect(queue.add).toHaveBeenCalledWith(
      'process-image',
      { schemaVersion: 2, mediaId: '40000000-0000-4000-8000-000000000001', generation: 3 },
      { jobId: 'media-40000000-0000-4000-8000-000000000001-g3' },
    );
  });
});
