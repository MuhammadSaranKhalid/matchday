import sharp from "sharp";
import { encode } from "blurhash";

/**
 * Computes BlurHash from a 32x32 raw pixel sample using Sharp.
 * Strips colorspace complexities and normalizes to standard RGB.
 */
export async function computeBlurHash(imageBuffer: Buffer): Promise<string> {
  const { data, info } = await sharp(imageBuffer)
    .resize(32, 32, { fit: "inside" })
    .ensureAlpha()
    .raw()
    .toBuffer({ resolveWithObject: true });

  const clampedArray = new Uint8ClampedArray(data);
  return encode(clampedArray, info.width, info.height, 4, 3);
}
