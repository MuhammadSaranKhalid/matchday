import { z } from 'zod';
import { uuidSchema } from './participation-response.schema.js';

export const freezeSquadSchema = z.strictObject({
  commandId: uuidSchema,

  // Optimistic concurrency token for this Entry's squad.
  expectedRevision: z.number().int().min(1),
});

export type FreezeSquadBody = z.infer<typeof freezeSquadSchema>;
