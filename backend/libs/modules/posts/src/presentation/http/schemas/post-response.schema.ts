import { z } from 'zod';

const uuidPattern =
  /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/;
const uuidSchema = z.string().regex(uuidPattern, 'Invalid UUID');

export const reservedMediaResponseSchema = z.strictObject({
  mediaId: uuidSchema,
  position: z.number().int().min(0),
  stagingPath: z.string().min(1),
  uploadToken: z.string().min(1),
});

export const createPostResponseSchema = z.strictObject({
  postId: uuidSchema,
  status: z.literal('draft'),
  media: z.array(reservedMediaResponseSchema),
});

export const postStatusResponseSchema = z.strictObject({
  status: z.enum(['processing', 'published', 'failed']),
});

export type CreatePostResponseDto = z.infer<typeof createPostResponseSchema>;
export type PostStatusResponseDto = z.infer<typeof postStatusResponseSchema>;
