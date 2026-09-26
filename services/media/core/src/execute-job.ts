import { MediaProcessingJob } from './contracts';
import { PermanentMediaError, TransientMediaError } from './errors';
import { MediaRepository } from './media-repository';
import { MediaStorage } from './media-storage';
import { createFeedReady, createOptimizedVariants } from './sharp-pipeline';

export interface MediaDependencies {
  repo: MediaRepository;
  storage: MediaStorage;
}

export async function executeMediaJob(
  job: MediaProcessingJob,
  deps: MediaDependencies,
): Promise<void> {
  switch (job.stage) {
    case 'feed':
      return processFeedJob(job, deps);
    case 'optimize':
      return processOptimizeJob(job, deps);
    default:
      throw new PermanentMediaError(`Unknown stage ${(job as any).stage}`);
  }
}

async function processFeedJob(
  job: MediaProcessingJob,
  deps: MediaDependencies,
): Promise<void> {
  const media = await deps.repo.fetchMedia(job.mediaId);
  if (!media) {
    throw new PermanentMediaError(`Media ${job.mediaId} not found in database`);
  }

  // Idempotent: if already at or past feed_ready, we are done
  if (['feed_ready', 'optimizing', 'optimized'].includes(media.status)) {
    return;
  }

  await deps.repo.setProcessingFeed(media.mediaId, media.processingAttempts + 1);

  // 1. Download staging source JPEG
  const sourceBuffer = await deps.storage.downloadStaging(media.stagingPath);

  // 2. Generate 1080 WebP + BlurHash
  const result = await createFeedReady(sourceBuffer);

  // 3. Upload immutable 1080 asset
  const targetPath = `${media.finalPrefix}1080.webp`;
  await deps.storage.uploadFinal(targetPath, result.variant1080.buffer);

  // 4. Mark feed ready & activate post
  await deps.repo.markFeedReady({
    mediaId: media.mediaId,
    sourceWidth: result.sourceWidth,
    sourceHeight: result.sourceHeight,
    displayWidth: result.displayWidth,
    displayHeight: result.displayHeight,
    blurhash: result.blurhash,
    variant1080: {
      path: targetPath,
      width: result.variant1080.width,
      height: result.variant1080.height,
      bytes: result.variant1080.bytes,
      mime: result.variant1080.mime,
    },
  });
}

async function processOptimizeJob(
  job: MediaProcessingJob,
  deps: MediaDependencies,
): Promise<void> {
  const media = await deps.repo.fetchMedia(job.mediaId);
  if (!media) {
    throw new PermanentMediaError(`Media ${job.mediaId} not found for optimization`);
  }

  if (media.status === 'optimized') {
    return;
  }

  await deps.repo.setOptimizing(media.mediaId, media.optimizationAttempts + 1);

  // 1. Download staging source
  const sourceBuffer = await deps.storage.downloadStaging(media.stagingPath);

  // 2. Generate complete set of secondary variants (360, 540, 720, 2048)
  const result = await createOptimizedVariants(sourceBuffer);

  // 3. Upload each variant immutably
  const updatedVariants: Record<string, any> = { ...(media.variants || {}) };

  for (const [key, v] of Object.entries(result.variants)) {
    const variantPath = `${media.finalPrefix}${key}.webp`;
    await deps.storage.uploadFinal(variantPath, v.buffer);

    updatedVariants[key] = {
      path: variantPath,
      width: v.width,
      height: v.height,
      bytes: v.bytes,
      mime: v.mime,
    };
  }

  // 4. Update variants and delete staging source file (Point 28)
  await deps.repo.markOptimized(media.mediaId, updatedVariants);
  await deps.storage.deleteStaging(media.stagingPath);
}
