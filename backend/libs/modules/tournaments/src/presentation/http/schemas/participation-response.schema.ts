import { z } from 'zod';

const uuidPattern =
  /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/;
export const uuidSchema = z.string().regex(uuidPattern, 'Invalid UUID');

export const registerTeamResultSchema = z.strictObject({
  registrationId: uuidSchema,
  status: z.literal('pending'),
});

export const registerTeamResponseSchema = z.strictObject({
  result: registerTeamResultSchema,
  status: z.enum(['executed', 'replayed']),
});

export const approveRegistrationResultSchema = z.strictObject({
  registrationId: uuidSchema,
  entryId: uuidSchema,
  entryRevision: z.number().int(),
});

export const approveRegistrationResponseSchema = z.strictObject({
  result: approveRegistrationResultSchema,
  status: z.enum(['executed', 'replayed']),
});

export const rejectRegistrationResultSchema = z.strictObject({
  registrationId: uuidSchema,
  status: z.literal('rejected'),
});

export const rejectRegistrationResponseSchema = z.strictObject({
  result: rejectRegistrationResultSchema,
  status: z.enum(['executed', 'replayed']),
});

export const withdrawPendingRegistrationResultSchema = z.strictObject({
  registrationId: uuidSchema,
  status: z.literal('withdrawn'),
});

export const withdrawPendingRegistrationResponseSchema = z.strictObject({
  result: withdrawPendingRegistrationResultSchema,
  status: z.enum(['executed', 'replayed']),
});

export const withdrawTournamentEntryResultSchema = z.strictObject({
  entryId: uuidSchema,
  status: z.literal('withdrawn'),
  entryRevision: z.number().int(),
});

export const withdrawTournamentEntryResponseSchema = z.strictObject({
  result: withdrawTournamentEntryResultSchema,
  status: z.enum(['executed', 'replayed']),
});

export const freezeSquadResultSchema = z.strictObject({
  entryId: uuidSchema,
  squadState: z.literal('frozen'),
  squadRevision: z.number().int(),
});

export const freezeSquadResponseSchema = z.strictObject({
  result: freezeSquadResultSchema,
  status: z.enum(['executed', 'replayed']),
});

export const addSquadMemberResultSchema = z.strictObject({
  squadMemberId: uuidSchema,
  squadRevision: z.number().int(),
});

export const addSquadMemberResponseSchema = z.strictObject({
  result: addSquadMemberResultSchema,
  status: z.enum(['executed', 'replayed']),
});

export const removeSquadMemberResultSchema = z.strictObject({
  squadMemberId: uuidSchema,
  squadRevision: z.number().int(),
});

export const removeSquadMemberResponseSchema = z.strictObject({
  result: removeSquadMemberResultSchema,
  status: z.enum(['executed', 'replayed']),
});

export const recordEntryPaymentResultSchema = z.strictObject({
  paymentId: uuidSchema,
  entryId: uuidSchema,
  amount: z.number().positive(),
});

export const recordEntryPaymentResponseSchema = z.strictObject({
  result: recordEntryPaymentResultSchema,
  status: z.enum(['executed', 'replayed']),
});

export const voidEntryPaymentResultSchema = z.strictObject({
  paymentId: uuidSchema,
  isVoid: z.literal(true),
});

export const voidEntryPaymentResponseSchema = z.strictObject({
  result: voidEntryPaymentResultSchema,
  status: z.enum(['executed', 'replayed']),
});

export type RegisterTeamResponseDto = z.infer<typeof registerTeamResponseSchema>;
export type ApproveRegistrationResponseDto = z.infer<typeof approveRegistrationResponseSchema>;
export type RejectRegistrationResponseDto = z.infer<typeof rejectRegistrationResponseSchema>;
export type WithdrawPendingRegistrationResponseDto = z.infer<
  typeof withdrawPendingRegistrationResponseSchema
>;
export type WithdrawTournamentEntryResponseDto = z.infer<
  typeof withdrawTournamentEntryResponseSchema
>;
export type FreezeSquadResponseDto = z.infer<typeof freezeSquadResponseSchema>;
export type AddSquadMemberResponseDto = z.infer<typeof addSquadMemberResponseSchema>;
export type RemoveSquadMemberResponseDto = z.infer<typeof removeSquadMemberResponseSchema>;
export type RecordEntryPaymentResponseDto = z.infer<typeof recordEntryPaymentResponseSchema>;
export type VoidEntryPaymentResponseDto = z.infer<typeof voidEntryPaymentResponseSchema>;

