export const MEDIA_POLICY = Object.freeze({
  stagingBucket: 'post-media-staging',
  finalBucket: 'post-media',
  source: Object.freeze({
    mimeType: 'image/jpeg',
    maxBytes: 15_728_640,
    maxLongEdge: 2_048,
    maxDecodedPixels: 16_777_216,
  }),
  variant: Object.freeze({
    mimeType: 'image/webp',
    cacheControl: '31536000',
    maxBytes: 5_242_880,
  }),
});
