import { z } from 'zod';
import { uuidSchema } from './participation-response.schema.js';

export const addSquadMemberSchema = z
  .strictObject({
    commandId: uuidSchema,
    userId: uuidSchema.optional(),
    unclaimedId: uuidSchema.optional(),

    // Optimistic concurrency token for this Entry's squad.
    expectedRevision: z.number().int().min(1),
  })
  .refine(
    (data) =>
      (Boolean(data.userId) && !data.unclaimedId) ||
      (Boolean(data.unclaimedId) && !data.userId),
    {
      message:
        'Squad member must specify exactly one of userId or unclaimedId',
    },
  );

export type AddSquadMemberBody = z.infer<
  typeof addSquadMemberSchema
>;
