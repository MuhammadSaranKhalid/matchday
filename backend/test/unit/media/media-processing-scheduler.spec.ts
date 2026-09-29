import { describe, expect, it, vi } from 'vitest';

import { MediaProcessingScheduler } from '../../../libs/modules/media/src/application/media-processing-scheduler.js';
import type { MediaJobProducer } from '../../../libs/modules/media/src/application/ports/media-job.producer.js';

describe('MediaProcessingScheduler', () => {
  it('delegates scheduleProcessing to producer.enqueueImage', async () => {
    const producer: MediaJobProducer = {
      enqueueImage: vi.fn().mockResolvedValue(undefined),
    };
    const scheduler = new MediaProcessingScheduler(producer);

    await scheduler.scheduleProcessing('media-id-123');

    expect(producer.enqueueImage).toHaveBeenCalledWith('media-id-123');
  });

  it('propagates producer errors', async () => {
    const failure = new Error('queue connection failed');
    const producer: MediaJobProducer = {
      enqueueImage: vi.fn().mockRejectedValue(failure),
    };
    const scheduler = new MediaProcessingScheduler(producer);

    await expect(scheduler.scheduleProcessing('media-id-123')).rejects.toThrow(
      'queue connection failed',
    );
  });
});
