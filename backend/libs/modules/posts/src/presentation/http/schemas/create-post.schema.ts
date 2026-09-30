import { z } from 'zod';
import { MEDIA_POLICY } from '@modules/media';

export const postMediaSchema = z.strictObject({
  width: z.number().int().min(1).max(MEDIA_POLICY.source.maxLongEdge),
  height: z.number().int().min(1).max(MEDIA_POLICY.source.maxLongEdge),
  bytes: z.number().int().min(1).max(MEDIA_POLICY.source.maxBytes),
  mimeType: z.literal(MEDIA_POLICY.source.mimeType),
});

const uuidPattern =
  /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/;
const uuidSchema = z.string().regex(uuidPattern, 'Invalid UUID');

export const createPostSchema = z.strictObject({
  clientCommandId: uuidSchema,
  publisherType: z.enum(['user', 'team', 'tournament']),
  publisherId: uuidSchema,
  postKind: z.string().trim().min(1).max(64),
  text: z.string().max(2000).optional(),
  media: z.array(postMediaSchema).max(4),
});
