import { z } from 'zod';
import { uuidSchema } from './participation-response.schema.js';

export const addSquadMemberSchema = z
  .strictObject({
    commandId: uuidSchema,
    userId: uuidSchema.optional(),
    unclaimedId: uuidSchema.optional(),
    expectedRevision: z.number().int().positive().optional(),
  })
  .refine(
    (data) =>
      (Boolean(data.userId) && !data.unclaimedId) ||
      (Boolean(data.unclaimedId) && !data.userId),
    { message: 'Squad member must specify exactly one of userId or unclaimedId' },
  );

export type AddSquadMemberBody = z.infer<typeof addSquadMemberSchema>;
