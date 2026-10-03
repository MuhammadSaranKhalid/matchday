import { z } from 'zod';
import { uuidSchema } from './participation-response.schema.js';

export const paymentChannelSchema = z.enum([
  'cash',
  'jazzcash',
  'easypaisa',
  'bank_transfer',
  'other',
]);

export const recordPaymentSchema = z.strictObject({
  commandId: uuidSchema,
  amount: z.number().positive(),
  paymentChannel: paymentChannelSchema,
  paymentReference: z.string().trim().max(100).optional(),
  notes: z.string().trim().max(500).optional(),
});

export type RecordPaymentBody = z.infer<typeof recordPaymentSchema>;
