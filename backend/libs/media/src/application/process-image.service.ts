import { join } from 'node:path';

import type { MediaObjectStorage } from './ports/media-object-storage.js';
import {
  type ImageTransformer,
  PermanentImageError,
} from './ports/image-transformer.js';
import type { MediaRepository } from './ports/media-repository.js';
import type { ScratchWorkspace } from './ports/scratch-workspace.js';

export class PermanentMediaProcessingError extends Error {}

export class ProcessImageService {
  constructor(
    private readonly repository: MediaRepository,
    private readonly storage: MediaObjectStorage,
    private readonly transformer: ImageTransformer,
    private readonly scratch: ScratchWorkspace,
  ) {}

  async execute(mediaId: string, _attempt: number): Promise<void> {
    const claim = await this.repository.claim(mediaId);
    if (!claim.claimed || claim.media === undefined) return;
    const media = claim.media;
    try {
      if (media.pipelineVersion !== 1) {
        throw new PermanentImageError('unsupported_pipeline_version');
      }
      await this.scratch.use(async (workspace) => {
        const source = join(workspace, 'source.jpg');
        await this.storage.downloadStaging(media.stagingPath, source);
        const transformed = await this.transformer.transform(source, workspace);
        for (const variant of transformed.variants) {
          const finalPath = `${media.finalPrefix}/${variant.name}`;
          await this.storage.uploadVariant(finalPath, variant.path);
        }
        const durable = Object.freeze({
          ...transformed,
          variants: Object.freeze(transformed.variants.map((variant) => Object.freeze({
            ...variant,
            path: `${media.finalPrefix}/${variant.name}`,
          }))),
        });
        await this.repository.markReady(mediaId, durable);
        await this.storage.deleteStaging(media.stagingPath);
      });
    } catch (error) {
      const message = safeMessage(error);
      if (error instanceof PermanentImageError) {
        await this.repository.markFailed(mediaId, message);
        throw new PermanentMediaProcessingError(message);
      }
      await this.repository.releaseForRetry(mediaId, message);
      throw error;
    }
  }
}

function safeMessage(error: unknown): string {
  return error instanceof Error ? error.message.slice(0, 500) : 'media_processing_failed';
}
