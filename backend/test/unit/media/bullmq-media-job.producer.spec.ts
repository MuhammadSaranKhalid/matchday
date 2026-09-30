import { describe, expect, it, vi } from 'vitest';

import { BullMqMediaJobProducer } from '../../../libs/modules/media/src/infrastructure/queue/bullmq-media-job.producer.js';

describe('BullMqMediaJobProducer', () => {
  it('adds the V2 payload with deterministic media job ID when no job exists', async () => {
    const queue = {
      getJob: vi.fn().mockResolvedValue(null),
      add: vi.fn().mockResolvedValue({ id: 'media-job-id' }),
    };
    const producer = new BullMqMediaJobProducer(queue);

    await producer.enqueueImage('40000000-0000-4000-8000-000000000001');

    expect(queue.getJob).toHaveBeenCalledWith('media-40000000-0000-4000-8000-000000000001');
    expect(queue.add).toHaveBeenCalledWith(
      'process-image',
      { schemaVersion: 2, mediaId: '40000000-0000-4000-8000-000000000001', generation: 1 },
      { jobId: 'media-40000000-0000-4000-8000-000000000001' },
    );
  });

  it('deduplicates when an active or waiting job already exists', async () => {
    const existingJob = {
      getState: vi.fn().mockResolvedValue('active'),
      remove: vi.fn(),
    };
    const queue = {
      getJob: vi.fn().mockResolvedValue(existingJob),
      add: vi.fn(),
    };
    const producer = new BullMqMediaJobProducer(queue);

    await producer.enqueueImage('40000000-0000-4000-8000-000000000001');

    expect(existingJob.remove).not.toHaveBeenCalled();
    expect(queue.add).not.toHaveBeenCalled();
  });

  it('removes completed or failed retained jobs before adding', async () => {
    const existingJob = {
      getState: vi.fn().mockResolvedValue('failed'),
      remove: vi.fn().mockResolvedValue(undefined),
    };
    const queue = {
      getJob: vi.fn().mockResolvedValue(existingJob),
      add: vi.fn().mockResolvedValue({ id: 'media-job-id' }),
    };
    const producer = new BullMqMediaJobProducer(queue);

    await producer.enqueueImage('40000000-0000-4000-8000-000000000001', 2);

    expect(existingJob.remove).toHaveBeenCalledOnce();
    expect(queue.add).toHaveBeenCalledWith(
      'process-image',
      { schemaVersion: 2, mediaId: '40000000-0000-4000-8000-000000000001', generation: 2 },
      { jobId: 'media-40000000-0000-4000-8000-000000000001' },
    );
  });
});
