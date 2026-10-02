import type { TournamentCommandContext, TournamentCommandHandler } from '../ports/tournament-command.ports.js';
import type {
  TeamAuthorizationRepository,
  TournamentAuthorizationRepository,
  TournamentEntryRepository,
  TournamentSquadRepository,
} from '../ports/tournament-repository.ports.js';
import { TournamentError } from '../../domain/errors/tournament-error-codes.js';
import type {
  WithdrawTournamentEntryCommand,
  WithdrawTournamentEntryResult,
} from '../../domain/command/participation-commands.js';

export class WithdrawTournamentEntryHandler
  implements
    TournamentCommandHandler<WithdrawTournamentEntryCommand, WithdrawTournamentEntryResult>
{
  constructor(
    private readonly tournamentAuthRepo: TournamentAuthorizationRepository,
    private readonly teamAuthRepo: TeamAuthorizationRepository,
    private readonly entryRepo: TournamentEntryRepository,
    private readonly squadRepo: TournamentSquadRepository,
  ) {}

  async execute(
    context: TournamentCommandContext,
    command: WithdrawTournamentEntryCommand,
  ): Promise<WithdrawTournamentEntryResult> {
    const { tx, principal } = context;
    const tournamentId = command.resources.tournamentId!;
    const entryId = command.resources.entryId!;

    // 1. Lock entry
    const entry = await this.entryRepo.lockEntry(tx, entryId);

    // 2. Validate belongs to tournament
    if (entry.tournamentId !== tournamentId) {
      throw TournamentError.notFound(
        `Entry ${entryId} does not belong to tournament ${tournamentId}`,
        { entryId, tournamentId },
      );
    }

    // 3. Entry must be active
    if (entry.status !== 'active') {
      throw TournamentError.invalidState(
        `Cannot withdraw entry with status '${entry.status}'`,
        { entryId, status: entry.status },
      );
    }

    // 4. Authorization: actor must be team authority OR tournament entries.manage
    const [isTeamAuth, isTournamentAuth] = await Promise.all([
      this.teamAuthRepo.can(tx, entry.teamId, 'team.tournament.enter'),
      this.tournamentAuthRepo.can(tx, tournamentId, 'tournament.entries.manage'),
    ]);

    if (!isTeamAuth && !isTournamentAuth) {
      throw TournamentError.forbidden(
        `Actor does not have authority to withdraw entry ${entryId}`,
        { entryId, actorId: principal.userId },
      );
    }

    // 5. Remove all active squad members (soft delete, preserves history)
    await this.squadRepo.removeAllActiveMembersForEntry(tx, {
      entryId,
      removedBy: principal.userId,
      removalReason: command.payload.reason ?? 'Entry withdrawn',
    });

    // 6. Withdraw the entry
    const withdrawn = await this.entryRepo.withdrawEntry(tx, {
      entryId,
      withdrawnBy: principal.userId,
      withdrawalReason: command.payload.reason,
    });

    return {
      entryId: withdrawn.entryId,
      status: 'withdrawn',
      entryRevision: withdrawn.squadRevision,
    };
  }
}
