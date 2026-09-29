export interface TransformedVariant {
  readonly name: `${number}.webp`;
  readonly path: string;
  readonly width: number;
  readonly height: number;
  readonly bytes: number;
  readonly mimeType: 'image/webp';
}

export interface TransformedImage {
  readonly sourceWidth: number;
  readonly sourceHeight: number;
  readonly displayWidth: number;
  readonly displayHeight: number;
  readonly blurhash: string;
  readonly variants: readonly TransformedVariant[];
}

export interface ImageTransformer {
  transform(source: string, workspace: string): Promise<TransformedImage>;
}

export class PermanentImageError extends Error {}
