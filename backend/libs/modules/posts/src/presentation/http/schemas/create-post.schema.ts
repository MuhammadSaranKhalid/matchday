import { z } from 'zod';
import { MEDIA_POLICY } from '@modules/media';

export const postMediaSchema = z.object({
  width: z.number().int().min(1).max(MEDIA_POLICY.source.maxLongEdge),
  height: z.number().int().min(1).max(MEDIA_POLICY.source.maxLongEdge),
  bytes: z.number().int().min(1).max(MEDIA_POLICY.source.maxBytes),
  mimeType: z.literal(MEDIA_POLICY.source.mimeType),
});

export const createPostSchema = z.object({
  clientCommandId: z.string().uuid(),
  publisherType: z.enum(['user', 'team', 'tournament']),
  publisherId: z.string().uuid(),
  postKind: z.string().trim().min(1).max(64),
  text: z.string().max(2000).optional(),
  media: z.array(postMediaSchema).max(4),
});

export type CreatePostInput = z.infer<typeof createPostSchema>;
