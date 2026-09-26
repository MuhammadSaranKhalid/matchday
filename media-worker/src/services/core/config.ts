export const MEDIA_PIPELINE_VERSION = 1;

export const IMAGE_VARIANTS = {
  360: { width: 360, quality: 80 },
  540: { width: 540, quality: 80 },
  720: { width: 720, quality: 80 },
  1080: { width: 1080, quality: 82 },
  2048: { width: 2048, height: 2048, quality: 84 },
} as const;
