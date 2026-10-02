import { z } from 'zod';
import { uuidSchema } from './participation-response.schema.js';

export const freezeSquadSchema = z.strictObject({
  commandId: uuidSchema,
  expectedRevision: z.number().int().min(1).optional(),
});

export type FreezeSquadBody = z.infer<typeof freezeSquadSchema>;
