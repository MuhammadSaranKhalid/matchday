export type MediaResizeRule =
  | Readonly<{ kind: 'width'; pixels: number }>
  | Readonly<{ kind: 'max-edge'; pixels: number }>;

export interface MediaOutputVariant {
  readonly name: `${number}.webp`;
  readonly resize: MediaResizeRule;
  readonly quality: number;
}

export interface MediaOutputContract {
  readonly format: 'webp';
  readonly execution: 'sequential';
  readonly withoutEnlargement: true;
  readonly variants: readonly MediaOutputVariant[];
}

export const MEDIA_OUTPUT_CONTRACT = {
  format: 'webp',
  execution: 'sequential',
  withoutEnlargement: true,
  variants: [
    { name: '360.webp', resize: { kind: 'width', pixels: 360 }, quality: 80 },
    { name: '540.webp', resize: { kind: 'width', pixels: 540 }, quality: 80 },
    { name: '720.webp', resize: { kind: 'width', pixels: 720 }, quality: 80 },
    { name: '1080.webp', resize: { kind: 'width', pixels: 1080 }, quality: 82 },
    { name: '2048.webp', resize: { kind: 'max-edge', pixels: 2048 }, quality: 84 },
  ],
} as const satisfies MediaOutputContract;
