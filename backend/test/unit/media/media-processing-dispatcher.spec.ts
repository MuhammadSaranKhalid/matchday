import { describe, expect, it, vi } from 'vitest';

import { MediaProcessingDispatcher } from '../../../libs/modules/media/src/application/media-processing-dispatcher.js';
import type { MediaJobProducer } from '../../../libs/modules/media/src/application/ports/media-job.producer.js';

describe('MediaProcessingDispatcher', () => {
  it('delegates dispatch to producer.enqueueImage', async () => {
    const producer: MediaJobProducer = {
      enqueueImage: vi.fn().mockResolvedValue(undefined),
    };
    const dispatcher = new MediaProcessingDispatcher(producer);

    await dispatcher.dispatch('media-id-123');

    expect(producer.enqueueImage).toHaveBeenCalledWith('media-id-123');
  });

  it('propagates producer errors', async () => {
    const failure = new Error('queue connection failed');
    const producer: MediaJobProducer = {
      enqueueImage: vi.fn().mockRejectedValue(failure),
    };
    const dispatcher = new MediaProcessingDispatcher(producer);

    await expect(dispatcher.dispatch('media-id-123')).rejects.toThrow(
      'queue connection failed',
    );
  });
});
