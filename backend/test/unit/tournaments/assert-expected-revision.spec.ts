import { describe, expect, it } from 'vitest';
import { assertExpectedRevision } from '../../../libs/modules/tournaments/src/domain/revision/assert-expected-revision.js';
import {
  TOURNAMENT_ERROR_CODES,
  TournamentError,
} from '../../../libs/modules/tournaments/src/domain/errors/tournament-error-codes.js';

describe('assertExpectedRevision', () => {
  it('does nothing when expected revision is undefined', () => {
    expect(() => assertExpectedRevision(undefined, 5)).not.toThrow();
  });

  it('does nothing when expected revision matches actual revision', () => {
    expect(() => assertExpectedRevision(4, 4)).not.toThrow();
  });

  it('throws TournamentError with STALE_REVISION and kind conflict on mismatch', () => {
    try {
      assertExpectedRevision(4, 5);
      expect.fail('Should have thrown');
    } catch (error) {
      expect(error).toBeInstanceOf(TournamentError);
      const tournamentError = error as TournamentError;
      expect(tournamentError.code).toBe(TOURNAMENT_ERROR_CODES.STALE_REVISION);
      expect(tournamentError.kind).toBe('conflict');
      expect(tournamentError.details).toEqual({
        expectedRevision: 4,
        actualRevision: 5,
      });
    }
  });
});
