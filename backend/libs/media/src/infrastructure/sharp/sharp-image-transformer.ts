import { stat } from 'node:fs/promises';
import { join } from 'node:path';

import { encode } from 'blurhash';
import sharp, { type Metadata } from 'sharp';

import {
  type ImageTransformer,
  PermanentImageError,
  type TransformedImage,
  type TransformedVariant,
} from '../../application/ports/image-transformer.js';
import { MEDIA_OUTPUT_CONTRACT } from '../../domain/media-output-contract.js';
import { MEDIA_POLICY } from '../../domain/media-policy.js';

export class SharpImageTransformer implements ImageTransformer {
  async transform(source: string, workspace: string): Promise<TransformedImage> {
    const sourceStat = await stat(source);
    if (sourceStat.size > MEDIA_POLICY.source.maxBytes) {
      throw new PermanentImageError('source_too_large');
    }
    let metadata: Metadata;
    try {
      metadata = await sharp(source, { limitInputPixels: MEDIA_POLICY.source.maxDecodedPixels })
        .metadata();
    } catch {
      throw new PermanentImageError('invalid_image');
    }
    if (metadata.format !== 'jpeg') throw new PermanentImageError('source_must_be_jpeg');
    if ((metadata.pages ?? 1) !== 1) throw new PermanentImageError('animated_image_not_allowed');
    const orientedWidth = metadata.autoOrient.width;
    const orientedHeight = metadata.autoOrient.height;
    if (orientedWidth === undefined || orientedHeight === undefined) {
      throw new PermanentImageError('missing_dimensions');
    }
    if (Math.max(orientedWidth, orientedHeight) > MEDIA_POLICY.source.maxLongEdge) {
      throw new PermanentImageError('source_dimensions_exceeded');
    }

    const variants: TransformedVariant[] = [];
    for (const variant of MEDIA_OUTPUT_CONTRACT.variants) {
      const path = join(workspace, variant.name);
      const resize = variant.resize.kind === 'width'
        ? { width: variant.resize.pixels }
        : { width: variant.resize.pixels, height: variant.resize.pixels, fit: 'inside' as const };
      const info = await sharp(source, { limitInputPixels: MEDIA_POLICY.source.maxDecodedPixels })
        .autoOrient()
        .resize({ ...resize, withoutEnlargement: true })
        .webp({ quality: variant.quality })
        .toFile(path);
      variants.push(Object.freeze({
        name: variant.name,
        path,
        width: info.width,
        height: info.height,
        bytes: info.size,
        mimeType: 'image/webp' as const,
      }));
    }

    const { data, info } = await sharp(source)
      .autoOrient()
      .resize({ width: 32, height: 32, fit: 'inside' })
      .ensureAlpha()
      .raw()
      .toBuffer({ resolveWithObject: true });
    const blurhash = encode(new Uint8ClampedArray(data), info.width, info.height, 4, 3);
    const display = variants.find((variant) => variant.name === '1080.webp') ?? variants.at(-1)!;
    return Object.freeze({
      sourceWidth: orientedWidth,
      sourceHeight: orientedHeight,
      displayWidth: display.width,
      displayHeight: display.height,
      blurhash,
      variants: Object.freeze(variants),
    });
  }
}
