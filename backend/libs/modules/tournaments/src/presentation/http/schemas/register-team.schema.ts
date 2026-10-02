import { z } from 'zod';
import { uuidSchema } from './participation-response.schema.js';

export const proposedSquadMemberSchema = z
  .strictObject({
    userId: uuidSchema.optional(),
    unclaimedId: uuidSchema.optional(),
  })
  .refine(
    (data) =>
      (data.userId !== undefined && data.userId !== null) ||
      (data.unclaimedId !== undefined && data.unclaimedId !== null),
    { message: 'Proposed squad member must specify either userId or unclaimedId' },
  );

export const registerTeamSchema = z.strictObject({
  commandId: uuidSchema,
  teamId: uuidSchema,
  message: z.string().trim().max(500).optional(),
  squadProposal: z.array(proposedSquadMemberSchema).default([]),
});

export type RegisterTeamBody = z.infer<typeof registerTeamSchema>;
