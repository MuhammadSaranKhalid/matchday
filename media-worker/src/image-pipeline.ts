import sharp from 'sharp';
import { encode } from 'blurhash';

export interface FeedReadyResult {
  sourceWidth: number;
  sourceHeight: number;
  width: number;
  height: number;
  buffer: Buffer;
  bytes: number;
  blurhash: string;
}

export interface OptimizedVariantsResult {
  [key: string]: {
    buffer: Buffer;
    width: number;
    height: number;
    bytes: number;
  };
}

/**
 * Priority 1: Fast-path feed-ready transformation.
 * Generates 1080.webp and calculates BlurHash on a tiny 32px downsample.
 */
export async function createFeedReady(source: Buffer): Promise<FeedReadyResult> {
  const base = sharp(source, { failOn: 'error' }).rotate();
  const original = await base.metadata();

  // 1. Generate 1080px WebP feed asset
  const feed = await base
    .clone()
    .resize({
      width: 1080,
      withoutEnlargement: true,
    })
    .webp({
      quality: 82,
      smartSubsample: true,
    })
    .toBuffer({ resolveWithObject: true });

  // 2. Downsample to 32px raw buffer for fast BlurHash encode
  const tiny = await base
    .clone()
    .resize({
      width: 32,
      height: 32,
      fit: 'inside',
      withoutEnlargement: true,
    })
    .ensureAlpha()
    .raw()
    .toBuffer({ resolveWithObject: true });

  const blurhash = encode(
    new Uint8ClampedArray(tiny.data),
    tiny.info.width,
    tiny.info.height,
    4,
    3,
  );

  return {
    sourceWidth: original.width ?? 0,
    sourceHeight: original.height ?? 0,
    width: feed.info.width,
    height: feed.info.height,
    buffer: feed.data,
    bytes: feed.data.length,
    blurhash,
  };
}

/**
 * Priority 2: Generates responsive derivatives (360, 540, 720, 2048) in background.
 * Respects source aspect ratio and never upscales.
 */
export async function createOptimizedVariants(source: Buffer): Promise<OptimizedVariantsResult> {
  const base = sharp(source, { failOn: 'error' }).rotate();

  async function widthVariant(width: number, quality = 80) {
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
    };
  }

  const [w360, w540, w720, viewer] = await Promise.all([
    widthVariant(360, 80),
    widthVariant(540, 80),
    widthVariant(720, 80),
    base
      .clone()
      .resize({
        width: 2048,
        height: 2048,
        fit: 'inside',
        withoutEnlargement: true,
      })
      .webp({
        quality: 84,
        smartSubsample: true,
      })
      .toBuffer({ resolveWithObject: true })
      .then((res) => ({
        buffer: res.data,
        width: res.info.width,
        height: res.info.height,
        bytes: res.data.length,
      })),
  ]);

  return {
    '360': w360,
    '540': w540,
    '720': w720,
    '2048': viewer,
  };
}
