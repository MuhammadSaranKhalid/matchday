import { z } from 'zod';
import { uuidSchema } from './participation-response.schema.js';

export const removeSquadMemberSchema = z.strictObject({
  commandId: uuidSchema,
  reason: z.string().trim().max(500).optional(),

  // Optimistic concurrency token for this Entry's squad.
  expectedRevision: z.number().int().min(1),
});

export type RemoveSquadMemberBody = z.infer<
  typeof removeSquadMemberSchema
>;
