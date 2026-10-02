import { z } from 'zod';
import { uuidSchema } from './participation-response.schema.js';

export const withdrawPendingRegistrationSchema = z.strictObject({
  commandId: uuidSchema,
  reason: z.string().trim().max(500).optional(),
});

export type WithdrawPendingRegistrationBody = z.infer<
  typeof withdrawPendingRegistrationSchema
>;
