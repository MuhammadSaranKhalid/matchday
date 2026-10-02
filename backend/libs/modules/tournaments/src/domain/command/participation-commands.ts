import type { TournamentCommand } from './tournament-command.js';

export interface ProposedSquadMember {
  readonly userId?: string;
  readonly unclaimedId?: string;
}

export type PaymentChannelType =
  | 'cash'
  | 'jazzcash'
  | 'easypaisa'
  | 'bank_transfer'
  | 'other';

// ─── 1. RegisterTeam ──────────────────────────────────────────────────────────

export interface RegisterTeamPayload {
  readonly teamId: string;
  readonly message?: string;
  readonly squadProposal: readonly ProposedSquadMember[];
}

export interface RegisterTeamResult {
  readonly registrationId: string;
  readonly status: 'pending';
}

export type RegisterTeamCommand = TournamentCommand<RegisterTeamPayload>;

// ─── 2. ApproveRegistration ──────────────────────────────────────────────────

export interface ApproveRegistrationPayload {
  readonly [key: string]: never;
}

export interface ApproveRegistrationResult {
  readonly registrationId: string;
  readonly entryId: string;
  readonly entryRevision: number;
}

export type ApproveRegistrationCommand = TournamentCommand<ApproveRegistrationPayload>;

// ─── 3. RejectRegistration ───────────────────────────────────────────────────

export interface RejectRegistrationPayload {
  readonly reason?: string;
}

export interface RejectRegistrationResult {
  readonly registrationId: string;
  readonly status: 'rejected';
}

export type RejectRegistrationCommand = TournamentCommand<RejectRegistrationPayload>;

// ─── 4. WithdrawPendingRegistration ──────────────────────────────────────────

export interface WithdrawPendingRegistrationPayload {
  readonly reason?: string;
}

export interface WithdrawPendingRegistrationResult {
  readonly registrationId: string;
  readonly status: 'withdrawn';
}

export type WithdrawPendingRegistrationCommand = TournamentCommand<WithdrawPendingRegistrationPayload>;

// ─── 5. WithdrawTournamentEntry ──────────────────────────────────────────────

export interface WithdrawTournamentEntryPayload {
  readonly reason?: string;
}

export interface WithdrawTournamentEntryResult {
  readonly entryId: string;
  readonly status: 'withdrawn';
  readonly entryRevision: number;
}

export type WithdrawTournamentEntryCommand = TournamentCommand<WithdrawTournamentEntryPayload>;

// ─── 6. AddSquadMember ───────────────────────────────────────────────────────

export interface AddSquadMemberPayload {
  readonly userId?: string;
  readonly unclaimedId?: string;
}

export interface AddSquadMemberResult {
  readonly squadMemberId: string;
  readonly squadRevision: number;
}

export type AddSquadMemberCommand = TournamentCommand<AddSquadMemberPayload>;

// ─── 7. RemoveSquadMember ────────────────────────────────────────────────────

export interface RemoveSquadMemberPayload {
  readonly reason?: string;
}

export interface RemoveSquadMemberResult {
  readonly squadMemberId: string;
  readonly squadRevision: number;
}

export type RemoveSquadMemberCommand = TournamentCommand<RemoveSquadMemberPayload>;

// ─── 8. FreezeSquad ──────────────────────────────────────────────────────────

export interface FreezeSquadPayload {
  readonly [key: string]: never;
}

export interface FreezeSquadResult {
  readonly entryId: string;
  readonly squadState: 'frozen';
  readonly squadRevision: number;
}

export type FreezeSquadCommand = TournamentCommand<FreezeSquadPayload>;

// ─── 9. RecordEntryPayment ───────────────────────────────────────────────────

export interface RecordEntryPaymentPayload {
  readonly amount: number;
  readonly paymentChannel: PaymentChannelType;
  readonly paymentReference?: string;
  readonly notes?: string;
}

export interface RecordEntryPaymentResult {
  readonly paymentId: string;
  readonly entryId: string;
  readonly amount: number;
}

export type RecordEntryPaymentCommand = TournamentCommand<RecordEntryPaymentPayload>;

// ─── 10. VoidEntryPayment ────────────────────────────────────────────────────

export interface VoidEntryPaymentPayload {
  readonly voidReason: string;
}

export interface VoidEntryPaymentResult {
  readonly paymentId: string;
  readonly isVoid: boolean;
}

export type VoidEntryPaymentCommand = TournamentCommand<VoidEntryPaymentPayload>;
