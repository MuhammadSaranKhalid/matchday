import sharp from "sharp";
import { computeBlurHash } from "./blurhash";

export interface FeedReadyOutput {
  buffer: Buffer;
  width: number;
  height: number;
  blurhash: string;
}

export interface SingleVariantOutput {
  widthKey: number;
  buffer: Buffer;
  width: number;
  height: number;
  sizeBytes: number;
}

/**
 * Priority 1: Produces the canonical 1080 feed-ready asset + BlurHash.
 * Normalizes colorspace to sRGB, strips all EXIF/GPS metadata,
 * applies rotation, and disables artificial upscaling (withoutEnlargement).
 */
export async function createFeedReadyAsset(sourceBuffer: Buffer): Promise<FeedReadyOutput> {
  const image = sharp(sourceBuffer)
    .rotate() // auto-orient based on EXIF, then strips raw orientation tag
    .toColorspace("srgb");

  const metadata = await image.metadata();
  const originalWidth = metadata.width ?? 1080;
  const originalHeight = metadata.height ?? 1080;

  // Render 1080 feed variant (WebP q82)
  const feedImageBuffer = await image
    .clone()
    .resize({
      width: 1080,
      fit: "inside",
      withoutEnlargement: true,
    })
    .webp({ quality: 82, effort: 4 })
    .toBuffer();

  const feedMeta = await sharp(feedImageBuffer).metadata();
  const blurhash = await computeBlurHash(sourceBuffer);

  return {
    buffer: feedImageBuffer,
    width: feedMeta.width ?? originalWidth,
    height: feedMeta.height ?? originalHeight,
    blurhash,
  };
}

/**
 * Priority 2: Generates responsive derivatives (360, 540, 720, 2048) in background.
 * Respects source dimensions without artificial enlargement.
 */
export async function createOptimizationVariants(sourceBuffer: Buffer): Promise<SingleVariantOutput[]> {
  const baseImage = sharp(sourceBuffer)
    .rotate()
    .toColorspace("srgb");


  const targetSpecs: Array<{ width: number; quality: number }> = [
    { width: 360, quality: 80 },
    { width: 540, quality: 80 },
    { width: 720, quality: 80 },
    { width: 2048, quality: 84 },
  ];

  const results: SingleVariantOutput[] = [];

  for (const spec of targetSpecs) {
    // If source is physically smaller than target, sharp with withoutEnlargement
    // will produce a variant bounded by sourceWidth.
    const variantBuffer = await baseImage
      .clone()
      .resize({
        width: spec.width,
        fit: "inside",
        withoutEnlargement: true,
      })
      .webp({ quality: spec.quality, effort: 4 })
      .toBuffer();

    const variantMeta = await sharp(variantBuffer).metadata();

    results.push({
      widthKey: spec.width,
      buffer: variantBuffer,
      width: variantMeta.width ?? spec.width,
      height: variantMeta.height ?? spec.width,
      sizeBytes: variantBuffer.length,
    });
  }

  return results;
}
