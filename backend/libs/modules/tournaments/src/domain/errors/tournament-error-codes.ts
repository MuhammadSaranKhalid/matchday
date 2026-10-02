import {
  ApplicationError,
  type ApplicationErrorKind,
} from '@shared-kernel/errors/application-error.js';

export const TOURNAMENT_ERROR_CODES = {
  BAD_REQUEST: 'TOURNAMENT_BAD_REQUEST',
  VALIDATION_ERROR: 'TOURNAMENT_VALIDATION_ERROR',
  FORBIDDEN: 'TOURNAMENT_FORBIDDEN',
  NOT_FOUND: 'TOURNAMENT_NOT_FOUND',
  INVALID_STATE: 'TOURNAMENT_INVALID_STATE',
  RULE_VIOLATION: 'TOURNAMENT_RULE_VIOLATION',
  CONFLICT: 'TOURNAMENT_CONFLICT',
  STALE_REVISION: 'TOURNAMENT_STALE_REVISION',
  IDEMPOTENCY_CONFLICT: 'TOURNAMENT_IDEMPOTENCY_CONFLICT',
  CAPACITY_REACHED: 'TOURNAMENT_CAPACITY_REACHED',
  ENTRY_NOT_READY: 'TOURNAMENT_ENTRY_NOT_READY',
  DRAW_STALE: 'TOURNAMENT_DRAW_STALE',
} as const;

export type TournamentErrorCode =
  (typeof TOURNAMENT_ERROR_CODES)[keyof typeof TOURNAMENT_ERROR_CODES];

export class TournamentError extends ApplicationError {
  constructor(
    code: TournamentErrorCode,
    message: string,
    kind: ApplicationErrorKind,
    details?: unknown,
  ) {
    super(code, message, kind, details);
    this.name = 'TournamentError';
  }

  static badRequest(message: string, details?: unknown): TournamentError {
    return new TournamentError(TOURNAMENT_ERROR_CODES.BAD_REQUEST, message, 'validation', details);
  }

  static validation(message: string, details?: unknown): TournamentError {
    return new TournamentError(TOURNAMENT_ERROR_CODES.VALIDATION_ERROR, message, 'validation', details);
  }

  static forbidden(message: string, details?: unknown): TournamentError {
    return new TournamentError(TOURNAMENT_ERROR_CODES.FORBIDDEN, message, 'forbidden', details);
  }

  static notFound(message: string, details?: unknown): TournamentError {
    return new TournamentError(TOURNAMENT_ERROR_CODES.NOT_FOUND, message, 'not_found', details);
  }

  static invalidState(message: string, details?: unknown): TournamentError {
    return new TournamentError(TOURNAMENT_ERROR_CODES.INVALID_STATE, message, 'validation', details);
  }

  static ruleViolation(message: string, details?: unknown): TournamentError {
    return new TournamentError(TOURNAMENT_ERROR_CODES.RULE_VIOLATION, message, 'validation', details);
  }

  static conflict(message: string, details?: unknown): TournamentError {
    return new TournamentError(TOURNAMENT_ERROR_CODES.CONFLICT, message, 'conflict', details);
  }

  static staleRevision(expected: number, actual: number): TournamentError {
    return new TournamentError(
      TOURNAMENT_ERROR_CODES.STALE_REVISION,
      `Stale revision: expected ${expected} but actual is ${actual}`,
      'conflict',
      { expectedRevision: expected, actualRevision: actual },
    );
  }

  static idempotencyConflict(message: string, details?: unknown): TournamentError {
    return new TournamentError(TOURNAMENT_ERROR_CODES.IDEMPOTENCY_CONFLICT, message, 'conflict', details);
  }

  static capacityReached(message: string, details?: unknown): TournamentError {
    return new TournamentError(TOURNAMENT_ERROR_CODES.CAPACITY_REACHED, message, 'conflict', details);
  }

  static entryNotReady(message: string, details?: unknown): TournamentError {
    return new TournamentError(TOURNAMENT_ERROR_CODES.ENTRY_NOT_READY, message, 'validation', details);
  }

  static drawStale(message: string, details?: unknown): TournamentError {
    return new TournamentError(TOURNAMENT_ERROR_CODES.DRAW_STALE, message, 'conflict', details);
  }
}
