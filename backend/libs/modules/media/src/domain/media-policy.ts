export const MEDIA_POLICY = Object.freeze({
  source: Object.freeze({
    mimeType: 'image/jpeg',
    maxBytes: 15_728_640,
    maxLongEdge: 2_048,
    maxDecodedPixels: 16_777_216,
  }),
  variant: Object.freeze({
    mimeType: 'image/webp',
    maxBytes: 5_242_880,
  }),
});
