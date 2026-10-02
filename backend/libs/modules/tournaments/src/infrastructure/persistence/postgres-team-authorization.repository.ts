import type { CommandQueryExecutor } from '../../application/ports/tournament-command.ports.js';
import type { TeamAuthorizationRepository } from '../../application/ports/tournament-repository.ports.js';
import { TournamentError } from '../../domain/errors/tournament-error-codes.js';

export class PostgresTeamAuthorizationRepository implements TeamAuthorizationRepository {
  async can(
    tx: CommandQueryExecutor,
    teamId: string,
    permission: string,
  ): Promise<boolean> {
    const result = await tx.query<{ granted: boolean }>(
      `select public.can('team', $1::uuid, $2::text) as granted`,
      [teamId, permission],
    );

    return Boolean(result.rows[0]?.granted);
  }

  async require(
    tx: CommandQueryExecutor,
    teamId: string,
    permission: string,
  ): Promise<void> {
    const granted = await this.can(tx, teamId, permission);
    if (!granted) {
      throw TournamentError.forbidden(
        `Permission '${permission}' required on team ${teamId}`,
        { teamId, permission },
      );
    }
  }
}
