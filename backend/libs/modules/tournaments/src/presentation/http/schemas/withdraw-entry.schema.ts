import { z } from 'zod';
import { uuidSchema } from './participation-response.schema.js';

export const withdrawTournamentEntrySchema = z.strictObject({
  commandId: uuidSchema,
  reason: z.string().trim().max(500).optional(),

  // Optimistic concurrency token for the Tournament Entry Set.
  expectedRevision: z.number().int().min(1),
});

export type WithdrawTournamentEntryBody = z.infer<
  typeof withdrawTournamentEntrySchema
>;
