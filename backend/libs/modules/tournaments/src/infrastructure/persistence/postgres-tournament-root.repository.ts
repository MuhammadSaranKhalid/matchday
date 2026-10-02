import type { CommandQueryExecutor } from '../../application/ports/tournament-command.ports.js';
import type {
  TournamentRootRepository,
  TournamentRootSnapshot,
} from '../../application/ports/tournament-repository.ports.js';
import { TournamentError } from '../../domain/errors/tournament-error-codes.js';

interface TournamentRow extends Record<string, unknown> {
  tournament_id: string;
  sport_id: string;
  owner_user_id: string;
  publication_state: string;
  registration_state: string;
  entry_state: string;
  competition_state: string;
  termination_state: string;
  revision: number;
  entry_revision: number;
  max_teams: number | null;
  registration_deadline: string | Date | null;
  entry_fee: string | number;
}

export class PostgresTournamentRootRepository implements TournamentRootRepository {
  async lockTournament(
    tx: CommandQueryExecutor,
    tournamentId: string,
  ): Promise<TournamentRootSnapshot> {
    const result = await tx.query<TournamentRow>(
      `SELECT
        tournament_id,
        sport_id,
        owner_user_id,
        publication_state,
        registration_state,
        entry_state,
        competition_state,
        termination_state,
        revision,
        entry_revision,
        max_teams,
        registration_deadline,
        entry_fee
      FROM public.tournaments
      WHERE tournament_id = $1
      FOR UPDATE`,
      [tournamentId],
    );

    const row = result.rows[0];
    if (!row) {
      throw TournamentError.notFound(
        `Tournament ${tournamentId} not found`,
        { tournamentId },
      );
    }

    return this.mapRow(row);
  }

  async findTournament(
    tx: CommandQueryExecutor,
    tournamentId: string,
  ): Promise<TournamentRootSnapshot | null> {
    const result = await tx.query<TournamentRow>(
      `SELECT
        tournament_id,
        sport_id,
        owner_user_id,
        publication_state,
        registration_state,
        entry_state,
        competition_state,
        termination_state,
        revision,
        entry_revision,
        max_teams,
        registration_deadline,
        entry_fee
      FROM public.tournaments
      WHERE tournament_id = $1`,
      [tournamentId],
    );

    const row = result.rows[0];
    return row ? this.mapRow(row) : null;
  }

  private mapRow(row: TournamentRow): TournamentRootSnapshot {
    return {
      tournamentId: row.tournament_id,
      sportId: row.sport_id,
      ownerUserId: row.owner_user_id,
      publicationState: row.publication_state,
      registrationState: row.registration_state,
      entryState: row.entry_state,
      competitionState: row.competition_state,
      terminationState: row.termination_state,
      revision: Number(row.revision),
      entryRevision: Number(row.entry_revision),
      maxTeams: row.max_teams !== null && row.max_teams !== undefined ? Number(row.max_teams) : null,
      registrationDeadline:
        row.registration_deadline instanceof Date
          ? row.registration_deadline.toISOString().split('T')[0]!
          : typeof row.registration_deadline === 'string'
            ? row.registration_deadline
            : null,
      entryFee: Number(row.entry_fee ?? 0),
    };
  }
}
