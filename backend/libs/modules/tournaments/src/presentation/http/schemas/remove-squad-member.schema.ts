import { z } from 'zod';
import { uuidSchema } from './participation-response.schema.js';

export const removeSquadMemberSchema = z.strictObject({
  commandId: uuidSchema,
  reason: z.string().trim().max(500).optional(),
  expectedRevision: z.number().int().positive().optional(),
});

export type RemoveSquadMemberBody = z.infer<typeof removeSquadMemberSchema>;
