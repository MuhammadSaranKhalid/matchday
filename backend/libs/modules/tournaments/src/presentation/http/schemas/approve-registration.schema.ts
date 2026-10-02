import { z } from 'zod';
import { uuidSchema } from './participation-response.schema.js';

export const approveRegistrationSchema = z.strictObject({
  commandId: uuidSchema,
});

export type ApproveRegistrationBody = z.infer<typeof approveRegistrationSchema>;
