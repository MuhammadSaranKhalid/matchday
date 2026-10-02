import { TournamentError } from '../errors/tournament-error-codes.js';

export function assertExpectedRevision(
  expected: number | undefined,
  actual: number,
): void {
  if (expected === undefined) {
    return;
  }
  if (expected !== actual) {
    throw TournamentError.staleRevision(expected, actual);
  }
}
