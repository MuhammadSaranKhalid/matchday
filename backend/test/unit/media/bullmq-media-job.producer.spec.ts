import { describe, expect, it, vi } from 'vitest';

import { BullMqMediaJobProducer } from '../../../libs/modules/media/src/infrastructure/queue/bullmq-media-job.producer.js';

describe('BullMqMediaJobProducer', () => {
  it('enqueues process-image job with schemaVersion 1 and custom jobId', async () => {
    const queue = {
      add: vi.fn().mockResolvedValue({ id: 'media-40000000-0000-4000-8000-000000000001' }),
    };
    const producer = new BullMqMediaJobProducer(queue as never);

    await producer.enqueueImage('40000000-0000-4000-8000-000000000001');

    expect(queue.add).toHaveBeenCalledWith(
      'process-image',
      { schemaVersion: 1, mediaId: '40000000-0000-4000-8000-000000000001' },
      { jobId: 'media-40000000-0000-4000-8000-000000000001' },
    );
  });
});
