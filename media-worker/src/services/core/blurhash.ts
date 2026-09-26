import sharp from 'sharp';
import { encode } from 'blurhash';

/**
 * Computes BlurHash on a tiny 32px raw downsample off the main image.
 */
export async function computeBlurHash(baseSharp: sharp.Sharp): Promise<string> {
  const tiny = await baseSharp
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

  return encode(
    new Uint8ClampedArray(tiny.data),
    tiny.info.width,
    tiny.info.height,
    4,
    3,
  );
}
