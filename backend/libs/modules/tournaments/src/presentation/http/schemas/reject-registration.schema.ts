import { z } from 'zod';
import { uuidSchema } from './participation-response.schema.js';

export const rejectRegistrationSchema = z.strictObject({
  commandId: uuidSchema,
  reason: z.string().trim().max(500).optional(),
});

export type RejectRegistrationBody = z.infer<typeof rejectRegistrationSchema>;
