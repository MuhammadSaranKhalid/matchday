import type { CommandQueryExecutor } from '../../application/ports/tournament-command.ports.js';
import type {
  TeamSnapshot,
  TeamTournamentRepository,
} from '../../application/ports/tournament-repository.ports.js';

interface TeamRow extends Record<string, unknown> {
  team_id: string;
  sport_id: string;
  status: string;
  team_name: string;
}

export class PostgresTeamTournamentRepository implements TeamTournamentRepository {
  async findTeam(
    tx: CommandQueryExecutor,
    teamId: string,
  ): Promise<TeamSnapshot | null> {
    const result = await tx.query<TeamRow>(
      `SELECT team_id, sport_id, status, team_name
       FROM public.teams
       WHERE team_id = $1`,
      [teamId],
    );
    const row = result.rows[0];
    if (!row) return null;
    return {
      teamId: row.team_id,
      sportId: row.sport_id,
      status: row.status,
      teamName: row.team_name,
    };
  }
}
