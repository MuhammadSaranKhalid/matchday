import { describe, expect, it, vi } from 'vitest';
import { UnrecoverableError } from 'bullmq';

import { MediaProcessor } from '../../../libs/modules/media/src/infrastructure/queue/media.processor.js';
import { PermanentMediaProcessingError } from '../../../libs/modules/media/src/application/process-image.service.js';

describe('MediaProcessor', () => {
  it('processes image job successfully', async () => {
    const processImage = { execute: vi.fn().mockResolvedValue(undefined) };
    const processor = new MediaProcessor(processImage as never);

    const job = {
      name: 'process-image',
      data: { schemaVersion: 1, mediaId: 'media-123' },
      attemptsMade: 0,
    };

    await processor.process(job as never);
    expect(processImage.execute).toHaveBeenCalledWith('media-123', 1, 3);
  });

  it('rejects unsupported schema version with UnrecoverableError', async () => {
    const processImage = { execute: vi.fn() };
    const processor = new MediaProcessor(processImage as never);

    const job = {
      name: 'process-image',
      data: { schemaVersion: 2, mediaId: 'media-123' },
      attemptsMade: 0,
    };

    await expect(processor.process(job as never)).rejects.toThrow(UnrecoverableError);
    expect(processImage.execute).not.toHaveBeenCalled();
  });

  it('maps PermanentMediaProcessingError to UnrecoverableError', async () => {
    const processImage = {
      execute: vi.fn().mockRejectedValue(new PermanentMediaProcessingError('unreadable_bytes')),
    };
    const processor = new MediaProcessor(processImage as never);

    const job = {
      name: 'process-image',
      data: { schemaVersion: 1, mediaId: 'media-123' },
      attemptsMade: 0,
    };

    await expect(processor.process(job as never)).rejects.toThrow(UnrecoverableError);
  });
});
