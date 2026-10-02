import type { CommandQueryExecutor } from './tournament-command.ports.js';

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
