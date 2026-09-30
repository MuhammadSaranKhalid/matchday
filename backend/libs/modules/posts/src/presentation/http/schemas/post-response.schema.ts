import { z } from 'zod';

export const reservedMediaResponseSchema = z.strictObject({
  mediaId: z.uuid(),
  position: z.number().int().min(0),
  stagingPath: z.string().min(1),
});

export const createPostResponseSchema = z.strictObject({
  postId: z.uuid(),
  status: z.literal('draft'),
  media: z.array(reservedMediaResponseSchema),
});

export const postStatusResponseSchema = z.strictObject({
  status: z.enum(['processing', 'published', 'failed']),
});

export type CreatePostResponseDto = z.infer<typeof createPostResponseSchema>;
export type PostStatusResponseDto = z.infer<typeof postStatusResponseSchema>;
