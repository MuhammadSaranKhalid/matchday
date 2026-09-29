import { describe, expect, it } from 'vitest';

import { MEDIA_OUTPUT_CONTRACT } from '../../../libs/modules/media/src/domain/media-output-contract.js';

describe('MEDIA_OUTPUT_CONTRACT', () => {
  it('defines the responsive variants consumed by the Flutter image selector', () => {
    expect(MEDIA_OUTPUT_CONTRACT.variants).toEqual([
      { name: '360.webp', resize: { kind: 'width', pixels: 360 }, quality: 80 },
      { name: '540.webp', resize: { kind: 'width', pixels: 540 }, quality: 80 },
      { name: '720.webp', resize: { kind: 'width', pixels: 720 }, quality: 80 },
      { name: '1080.webp', resize: { kind: 'width', pixels: 1080 }, quality: 82 },
      { name: '2048.webp', resize: { kind: 'max-edge', pixels: 2048 }, quality: 84 },
    ]);
  });

  it('requires sequential transforms without enlarging the source', () => {
    expect(MEDIA_OUTPUT_CONTRACT.execution).toBe('sequential');
    expect(MEDIA_OUTPUT_CONTRACT.withoutEnlargement).toBe(true);
    expect(MEDIA_OUTPUT_CONTRACT.format).toBe('webp');
  });
});
