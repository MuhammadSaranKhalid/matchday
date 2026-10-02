import type { CommandQueryExecutor } from '../../application/ports/tournament-command.ports.js';
import type { TournamentAuthorizationRepository } from '../../application/ports/tournament-repository.ports.js';
import { TournamentError } from '../../domain/errors/tournament-error-codes.js';

export class PostgresTournamentAuthorizationRepository
  implements TournamentAuthorizationRepository
{
  async can(
    tx: CommandQueryExecutor,
    tournamentId: string,
    permission: string,
  ): Promise<boolean> {
    const result = await tx.query<{ granted: boolean }>(
      `select public.can('tournament', $1::uuid, $2::text) as granted`,
      [tournamentId, permission],
    );

    return Boolean(result.rows[0]?.granted);
  }

  async require(
    tx: CommandQueryExecutor,
    tournamentId: string,
    permission: string,
  ): Promise<void> {
    const granted = await this.can(tx, tournamentId, permission);
    if (!granted) {
      throw TournamentError.forbidden(
        `Permission '${permission}' required on tournament ${tournamentId}`,
        { tournamentId, permission },
      );
    }
  }
}
