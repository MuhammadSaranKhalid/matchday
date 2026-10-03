import type { CommandQueryExecutor } from './tournament-command.ports.js';
import type { ProposedSquadMember } from '../../domain/command/participation-commands.js';

// ─── Tournament Authorization ────────────────────────────────────────────────

export const TOURNAMENT_AUTHORIZATION_REPOSITORY = Symbol('TOURNAMENT_AUTHORIZATION_REPOSITORY');

export interface TournamentAuthorizationRepository {
  can(
    tx: CommandQueryExecutor,
    tournamentId: string,
    permission: string,
  ): Promise<boolean>;

  require(
    tx: CommandQueryExecutor,
    tournamentId: string,
    permission: string,
  ): Promise<void>;
}

// ─── Team Authorization ──────────────────────────────────────────────────────

export const TEAM_AUTHORIZATION_REPOSITORY = Symbol('TEAM_AUTHORIZATION_REPOSITORY');

export interface TeamAuthorizationRepository {
  can(
    tx: CommandQueryExecutor,
    teamId: string,
    permission: string,
  ): Promise<boolean>;

  require(
    tx: CommandQueryExecutor,
    teamId: string,
    permission: string,
  ): Promise<void>;
}

// ─── Tournament Root ─────────────────────────────────────────────────────────

export interface TournamentRootSnapshot {
  readonly tournamentId: string;
  readonly sportId: string;
  readonly ownerUserId: string;
  readonly publicationState: string;
  readonly registrationState: string;
  readonly entryState: string;
  readonly competitionState: string;
  readonly terminationState: string;
  readonly revision: number;
  readonly entryRevision: number;
  readonly maxTeams: number | null;
  readonly registrationDeadline: string | null;
  readonly entryFee: number;
}

export const TOURNAMENT_ROOT_REPOSITORY = Symbol('TOURNAMENT_ROOT_REPOSITORY');

export interface TournamentRootRepository {
  lockTournament(
    tx: CommandQueryExecutor,
    tournamentId: string,
  ): Promise<TournamentRootSnapshot>;

  findTournament(
    tx: CommandQueryExecutor,
    tournamentId: string,
  ): Promise<TournamentRootSnapshot | null>;
}

// ─── Command Receipts ────────────────────────────────────────────────────────

export interface TournamentCommandReceiptRecord {
  readonly commandId: string;
  readonly actorId: string;
  readonly action: string;
  readonly tournamentId: string | null;
  readonly requestFingerprint: string;
  readonly responsePayload: unknown;
  readonly createdAt: Date;
  readonly completedAt: Date;
}

export const TOURNAMENT_COMMAND_RECEIPT_REPOSITORY = Symbol('TOURNAMENT_COMMAND_RECEIPT_REPOSITORY');

export interface TournamentCommandReceiptRepository {
  findReceipt(
    tx: CommandQueryExecutor,
    commandId: string,
  ): Promise<TournamentCommandReceiptRecord | null>;

  saveReceipt(
    tx: CommandQueryExecutor,
    receipt: {
      readonly commandId: string;
      readonly actorId: string;
      readonly action: string;
      readonly tournamentId?: string | null;
      readonly requestFingerprint: string;
      readonly responsePayload: unknown;
    },
  ): Promise<void>;
}

// ─── Registration Repository ─────────────────────────────────────────────────

export interface RegistrationSnapshot {
  readonly registrationId: string;
  readonly tournamentId: string;
  readonly teamId: string;
  readonly registeredBy: string | null;
  readonly registeredAt: Date;
  readonly status: 'pending' | 'approved' | 'rejected' | 'withdrawn';
  readonly message: string | null;
  readonly decisionReason: string | null;
  readonly decidedBy: string | null;
  readonly decidedAt: Date | null;
  readonly withdrawnAt: Date | null;
  readonly withdrawnBy: string | null;
  readonly withdrawalReason: string | null;
}

export interface ProposalMemberSnapshot {
  readonly proposalMemberId: string;
  readonly registrationId: string;
  readonly tournamentId: string;
  readonly teamId: string;
  readonly userId: string | null;
  readonly unclaimedId: string | null;
}

export const TOURNAMENT_REGISTRATION_REPOSITORY = Symbol('TOURNAMENT_REGISTRATION_REPOSITORY');

export interface TournamentRegistrationRepository {
  lockRegistration(
    tx: CommandQueryExecutor,
    registrationId: string,
  ): Promise<RegistrationSnapshot>;

  findRegistration(
    tx: CommandQueryExecutor,
    registrationId: string,
  ): Promise<RegistrationSnapshot | null>;

  hasPendingRegistration(
    tx: CommandQueryExecutor,
    tournamentId: string,
    teamId: string,
  ): Promise<boolean>;

  createRegistration(
    tx: CommandQueryExecutor,
    params: {
      readonly tournamentId: string;
      readonly teamId: string;
      readonly registeredBy: string;
      readonly message?: string;
    },
  ): Promise<string>;

  createProposalMembers(
    tx: CommandQueryExecutor,
    params: {
      readonly registrationId: string;
      readonly tournamentId: string;
      readonly teamId: string;
      readonly submittedBy: string;
      readonly members: readonly ProposedSquadMember[];
    },
  ): Promise<void>;

  getProposalMembers(
    tx: CommandQueryExecutor,
    registrationId: string,
  ): Promise<readonly ProposalMemberSnapshot[]>;

  resolveRegistration(
    tx: CommandQueryExecutor,
    params: {
      readonly registrationId: string;
      readonly status: 'approved' | 'rejected';
      readonly decidedBy: string;
      readonly decisionReason?: string;
    },
  ): Promise<void>;

  withdrawRegistration(
    tx: CommandQueryExecutor,
    params: {
      readonly registrationId: string;
      readonly withdrawnBy: string;
      readonly withdrawalReason?: string;
    },
  ): Promise<void>;
}

// ─── Entry Repository ────────────────────────────────────────────────────────

export interface EntrySnapshot {
  readonly entryId: string;
  readonly tournamentId: string;
  readonly teamId: string;
  readonly registrationId: string | null;
  readonly status: 'active' | 'withdrawn' | 'disqualified';
  readonly entrySource: string;
  readonly acceptedBy: string | null;
  readonly acceptedAt: Date;
  readonly withdrawnAt: Date | null;
  readonly withdrawnBy: string | null;
  readonly withdrawalReason: string | null;
  readonly squadState: 'editable' | 'frozen';
  readonly squadRevision: number;
  readonly squadFrozenAt: Date | null;
}

export const TOURNAMENT_ENTRY_REPOSITORY = Symbol('TOURNAMENT_ENTRY_REPOSITORY');

export interface TournamentEntryRepository {
  lockEntry(
    tx: CommandQueryExecutor,
    entryId: string,
  ): Promise<EntrySnapshot>;

  findEntry(
    tx: CommandQueryExecutor,
    entryId: string,
  ): Promise<EntrySnapshot | null>;

  findActiveEntryByTeam(
    tx: CommandQueryExecutor,
    tournamentId: string,
    teamId: string,
  ): Promise<EntrySnapshot | null>;

  countActiveEntries(
    tx: CommandQueryExecutor,
    tournamentId: string,
  ): Promise<number>;

  createEntry(
    tx: CommandQueryExecutor,
    params: {
      readonly tournamentId: string;
      readonly teamId: string;
      readonly registrationId: string;
      readonly acceptedBy: string;
      readonly entrySource?: string;
    },
  ): Promise<EntrySnapshot>;

  withdrawEntry(
    tx: CommandQueryExecutor,
    params: {
      readonly entryId: string;
      readonly withdrawnBy: string;
      readonly withdrawalReason?: string;
    },
  ): Promise<EntrySnapshot>;

  bumpSquadRevision(
    tx: CommandQueryExecutor,
    params: {
      readonly entryId: string;
      readonly expectedRevision?: number;
    },
  ): Promise<number>;

  freezeSquad(
    tx: CommandQueryExecutor,
    params: {
      readonly entryId: string;
      readonly expectedRevision?: number;
    },
  ): Promise<number>;
}

// ─── Squad Repository ────────────────────────────────────────────────────────

export interface SquadMemberSnapshot {
  readonly squadMemberId: string;
  readonly entryId: string;
  readonly tournamentId: string;
  readonly userId: string | null;
  readonly unclaimedId: string | null;
  readonly membershipStatus: 'active' | 'removed';
  readonly addedBy: string | null;
  readonly addedAt: Date;
  readonly removedBy: string | null;
  readonly removedAt: Date | null;
  readonly removalReason: string | null;
}

export const TOURNAMENT_SQUAD_REPOSITORY = Symbol('TOURNAMENT_SQUAD_REPOSITORY');

export interface TournamentSquadRepository {
  lockSquadMember(
    tx: CommandQueryExecutor,
    squadMemberId: string,
  ): Promise<SquadMemberSnapshot>;

  findSquadMember(
    tx: CommandQueryExecutor,
    squadMemberId: string,
  ): Promise<SquadMemberSnapshot | null>;

  isPlayerInActiveTeamRoster(
    tx: CommandQueryExecutor,
    teamId: string,
    player: ProposedSquadMember,
  ): Promise<boolean>;

  isPlayerInActiveTournamentSquad(
    tx: CommandQueryExecutor,
    tournamentId: string,
    player: ProposedSquadMember,
    excludeEntryId?: string,
  ): Promise<boolean>;

  materializeSquadFromProposal(
    tx: CommandQueryExecutor,
    params: {
      readonly entryId: string;
      readonly tournamentId: string;
      readonly teamId: string;
      readonly addedBy: string;
      readonly proposalMembers: readonly ProposalMemberSnapshot[];
    },
  ): Promise<void>;

  addOrReactivateSquadMember(
    tx: CommandQueryExecutor,
    params: {
      readonly entryId: string;
      readonly tournamentId: string;
      readonly player: ProposedSquadMember;
      readonly addedBy: string;
    },
  ): Promise<string>;

  removeSquadMember(
    tx: CommandQueryExecutor,
    params: {
      readonly squadMemberId: string;
      readonly removedBy: string;
      readonly removalReason?: string;
    },
  ): Promise<void>;

  removeAllActiveMembersForEntry(
    tx: CommandQueryExecutor,
    params: {
      readonly entryId: string;
      readonly removedBy: string;
      readonly removalReason: string;
    },
  ): Promise<void>;
}

// ─── Payment Repository ──────────────────────────────────────────────────────

export interface PaymentSnapshot {
  readonly paymentId: string;
  readonly entryId: string;
  readonly tournamentId: string;
  readonly amount: number;
  readonly paymentChannel: string;
  readonly paymentReference: string | null;
  readonly notes: string | null;
  readonly recordedBy: string | null;
  readonly recordedAt: Date;
  readonly isVoid: boolean;
  readonly voidedAt: Date | null;
  readonly voidedBy: string | null;
  readonly voidReason: string | null;
}

export const TOURNAMENT_PAYMENT_REPOSITORY = Symbol('TOURNAMENT_PAYMENT_REPOSITORY');

export interface TournamentPaymentRepository {
  lockPayment(
    tx: CommandQueryExecutor,
    paymentId: string,
  ): Promise<PaymentSnapshot>;

  findPayment(
    tx: CommandQueryExecutor,
    paymentId: string,
  ): Promise<PaymentSnapshot | null>;

  getEntryNonVoidedTotal(
    tx: CommandQueryExecutor,
    entryId: string,
  ): Promise<number>;

  createPayment(
    tx: CommandQueryExecutor,
    params: {
      readonly entryId: string;
      readonly tournamentId: string;
      readonly amount: number;
      readonly paymentChannel: string;
      readonly paymentReference?: string;
      readonly notes?: string;
      readonly recordedBy: string;
    },
  ): Promise<string>;

  voidPayment(
    tx: CommandQueryExecutor,
    params: {
      readonly paymentId: string;
      readonly voidedBy: string;
      readonly voidReason: string;
    },
  ): Promise<void>;
}

// ─── Team Repository ─────────────────────────────────────────────────────────

export interface TeamSnapshot {
  readonly teamId: string;
  readonly sportId: string;
  readonly status: string;
  readonly teamName: string;
}

export const TEAM_TOURNAMENT_REPOSITORY = Symbol('TEAM_TOURNAMENT_REPOSITORY');

export interface TeamTournamentRepository {
  findTeam(
    tx: CommandQueryExecutor,
    teamId: string,
  ): Promise<TeamSnapshot | null>;
}
