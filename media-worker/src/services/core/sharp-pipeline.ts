import sharp from 'sharp';
import { computeBlurHash } from './blurhash';
import { IMAGE_VARIANTS } from './config';
import { FeedReadyResult, OptimizedVariantsResult, ImageVariantInfo } from './contracts';
import { PermanentMediaError, TransientMediaError } from './errors';

export async function createFeedReady(sourceBuffer: Buffer): Promise<FeedReadyResult> {
  let base: sharp.Sharp;
  let metadata: sharp.Metadata;

  try {
    base = sharp(sourceBuffer, { failOn: 'error' }).rotate();
    metadata = await base.metadata();
  } catch (err) {
    throw new PermanentMediaError('Corrupt or unsupported image source', err);
  }

  const sourceWidth = metadata.width ?? 0;
  const sourceHeight = metadata.height ?? 0;

  if (sourceWidth === 0 || sourceHeight === 0) {
    throw new PermanentMediaError('Invalid image dimensions in source');
  }

  try {
    const feed = await base
      .clone()
      .resize({
        width: IMAGE_VARIANTS[1080].width,
        withoutEnlargement: true,
      })
      .webp({
        quality: IMAGE_VARIANTS[1080].quality,
        smartSubsample: true,
      })
      .toBuffer({ resolveWithObject: true });

    const blurhash = await computeBlurHash(base);

    return {
      sourceWidth,
      sourceHeight,
      displayWidth: feed.info.width,
      displayHeight: feed.info.height,
      blurhash,
      variant1080: {
        buffer: feed.data,
        width: feed.info.width,
        height: feed.info.height,
        bytes: feed.data.length,
        mime: 'image/webp',
      },
    };
  } catch (err) {
    throw new TransientMediaError('Sharp feed-ready transformation failed', err);
  }
}

export async function createOptimizedVariants(sourceBuffer: Buffer): Promise<OptimizedVariantsResult> {
  let base: sharp.Sharp;

  try {
    base = sharp(sourceBuffer, { failOn: 'error' }).rotate();
  } catch (err) {
    throw new PermanentMediaError('Corrupt or unsupported image source for optimization', err);
  }

  async function renderWidth(width: number, quality: number): Promise<ImageVariantInfo> {
    const res = await base
      .clone()
      .resize({
        width,
        withoutEnlargement: true,
      })
      .webp({
        quality,
        smartSubsample: true,
      })
      .toBuffer({ resolveWithObject: true });

    return {
      buffer: res.data,
      width: res.info.width,
      height: res.info.height,
      bytes: res.data.length,
      mime: 'image/webp',
    };
  }

  async function renderViewer(maxEdge: number, quality: number): Promise<ImageVariantInfo> {
    const res = await base
      .clone()
      .resize({
        width: maxEdge,
        height: maxEdge,
        fit: 'inside',
        withoutEnlargement: true,
      })
      .webp({
        quality,
        smartSubsample: true,
      })
      .toBuffer({ resolveWithObject: true });

    return {
      buffer: res.data,
      width: res.info.width,
      height: res.info.height,
      bytes: res.data.length,
      mime: 'image/webp',
    };
  }

  try {
    // Generate complete set of secondary variants (Point 27)
    const [v360, v540, v720, v2048] = await Promise.all([
      renderWidth(IMAGE_VARIANTS[360].width, IMAGE_VARIANTS[360].quality),
      renderWidth(IMAGE_VARIANTS[540].width, IMAGE_VARIANTS[540].quality),
      renderWidth(IMAGE_VARIANTS[720].width, IMAGE_VARIANTS[720].quality),
      renderViewer(IMAGE_VARIANTS[2048].width, IMAGE_VARIANTS[2048].quality),
    ]);

    return {
      variants: {
        '360': v360,
        '540': v540,
        '720': v720,
        '2048': v2048,
      },
    };
  } catch (err) {
    throw new TransientMediaError('Sharp secondary optimization failed', err);
  }
}
