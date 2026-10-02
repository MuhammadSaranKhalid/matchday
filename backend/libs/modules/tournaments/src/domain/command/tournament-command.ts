import { TournamentError } from '../errors/tournament-error-codes.js';

export const POSTGRES_UUID_TEXT_PATTERN =
  /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/;

/**
 * Validates that a value conforms to the PostgreSQL UUID textual format:
 * eight-four-four-four-twelve lowercase or uppercase hex digits separated by hyphens.
 *
 * This validates the **textual shape** accepted by PostgreSQL's `uuid` column type.
 * It does NOT enforce RFC 4122 / 9562 version or variant bits; all values that
 * PostgreSQL would accept as a valid UUID literal (v1–v8, nil, max) are permitted.
 *
 * The important requirement for commandId is that it is a valid UUID accepted
 * by the persistence contract — not that it is exclusively a particular version.
 */
export function isValidUuid(value: unknown): value is string {
  return typeof value === 'string' && POSTGRES_UUID_TEXT_PATTERN.test(value);
}


export interface TournamentCommandMetadata {
  readonly commandId: string;
  readonly expectedRevision?: number;
}

export interface TournamentResourceIdentifiers {
  readonly tournamentId?: string;
  readonly stageId?: string;
  readonly groupId?: string;
  readonly roundId?: string;
  readonly fixtureId?: string;
  readonly registrationId?: string;
  readonly entryId?: string;
  readonly [key: string]: string | undefined;
}

export interface TournamentCommand<TPayload = unknown> {
  readonly commandId: string;
  readonly action: string;
  readonly resources: TournamentResourceIdentifiers;
  readonly expectedRevision?: number;
  readonly payload: TPayload;
}

/**
 * Validates mandatory envelope fields for any incoming TournamentCommand prior to transaction execution.
 * Enforces:
 *  - commandId is a valid RFC-compatible UUID
 *  - action is a non-empty, non-whitespace string
 *  - expectedRevision, if supplied, is a strictly positive integer (>= 1)
 *  - resources is an object
 */
export function validateTournamentCommand(
  command: unknown,
): asserts command is TournamentCommand {
  if (!command || typeof command !== 'object') {
    throw TournamentError.badRequest('Command must be a non-null object');
  }

  const cmd = command as Partial<TournamentCommand>;

  if (!cmd.commandId || !isValidUuid(cmd.commandId)) {
    throw TournamentError.badRequest(
      'Command ID is required and must be a valid RFC-compatible UUID',
      { commandId: cmd.commandId },
    );
  }

  if (typeof cmd.action !== 'string' || cmd.action.trim() === '') {
    throw TournamentError.badRequest(
      'Action is required and cannot be empty or whitespace-only',
      { action: cmd.action },
    );
  }

  if (cmd.expectedRevision !== undefined) {
    if (
      typeof cmd.expectedRevision !== 'number' ||
      !Number.isInteger(cmd.expectedRevision) ||
      cmd.expectedRevision < 1 ||
      !Number.isFinite(cmd.expectedRevision)
    ) {
      throw TournamentError.badRequest(
        'expectedRevision must be a positive integer greater than or equal to 1',
        { expectedRevision: cmd.expectedRevision },
      );
    }
  }

  if (!cmd.resources || typeof cmd.resources !== 'object' || Array.isArray(cmd.resources)) {
    throw TournamentError.badRequest('resources must be a valid object');
  }
}

