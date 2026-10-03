import { z } from 'zod';
import { uuidSchema } from './participation-response.schema.js';

export const voidPaymentSchema = z.strictObject({
  commandId: uuidSchema,
  voidReason: z.string().trim().min(1).max(500),
});

export type VoidPaymentBody = z.infer<typeof voidPaymentSchema>;
