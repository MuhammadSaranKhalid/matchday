import { mkdtemp, writeFile } from 'node:fs/promises';
import { join } from 'node:path';
import { tmpdir } from 'node:os';

import sharp from 'sharp';
import { describe, expect, it } from 'vitest';

import { PermanentImageError } from '../../../libs/modules/media/src/application/ports/image-transformer.js';
import { SharpImageTransformer } from '../../../libs/modules/media/src/infrastructure/image/sharp-image-transformer.js';
import { ScratchWorkspaceService } from '../../../libs/modules/media/src/infrastructure/scratch/scratch-workspace.service.js';

describe('SharpImageTransformer', () => {
  it('auto-orients and generates all five sequential non-enlarged WebP variants', async () => {
    const scratch = new ScratchWorkspaceService(
      await mkdtemp(join(tmpdir(), 'matchday-transform-root-')),
    );
    await scratch.use(async (workspace) => {
      const source = join(workspace, 'source.jpg');
      await sharp({ create: { width: 120, height: 80, channels: 3,
        background: { r: 40, g: 100, b: 180 } } })
        .jpeg().withMetadata({ orientation: 6 }).toFile(source);
      const result = await new SharpImageTransformer().transform(source, workspace);
      expect(result.variants.map((variant) => variant.name)).toEqual([
        '360.webp', '540.webp', '720.webp', '1080.webp', '2048.webp',
      ]);
      expect(result.variants.every((variant) => variant.width <= 120 && variant.height <= 120))
        .toBe(true);
      expect(result.blurhash.length).toBeGreaterThan(10);
    });
  });

  it('rejects corrupt input as a permanent image error', async () => {
    const workspace = await mkdtemp(join(tmpdir(), 'matchday-corrupt-'));
    const source = join(workspace, 'source.jpg');
    await writeFile(source, 'not-a-jpeg');
    await expect(new SharpImageTransformer().transform(source, workspace))
      .rejects.toBeInstanceOf(PermanentImageError);
  });
});
