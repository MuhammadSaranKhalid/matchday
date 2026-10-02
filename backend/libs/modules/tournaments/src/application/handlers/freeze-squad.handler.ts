import type { TournamentCommandContext, TournamentCommandHandler } from '../ports/tournament-command.ports.js';
import type {
  TeamAuthorizationRepository,
  TournamentAuthorizationRepository,
  TournamentEntryRepository,
} from '../ports/tournament-repository.ports.js';
import { TournamentError } from '../../domain/errors/tournament-error-codes.js';
import type {
  FreezeSquadCommand,
  FreezeSquadResult,
} from '../../domain/command/participation-commands.js';

export class FreezeSquadHandler
  implements TournamentCommandHandler<FreezeSquadCommand, FreezeSquadResult>
{
  constructor(
    private readonly tournamentAuthRepo: TournamentAuthorizationRepository,
    private readonly teamAuthRepo: TeamAuthorizationRepository,
    private readonly entryRepo: TournamentEntryRepository,
  ) {}

  async execute(
    context: TournamentCommandContext,
    command: FreezeSquadCommand,
  ): Promise<FreezeSquadResult> {
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
        `Cannot freeze squad of entry with status '${entry.status}'`,
        { entryId, status: entry.status },
      );
    }

    // 4. Squad must be editable
    if (entry.squadState !== 'editable') {
      throw TournamentError.invalidState(
        `Squad is already frozen for entry ${entryId}`,
        { entryId, squadState: entry.squadState },
      );
    }

    // 5. Authorization: actor must be team authority OR tournament entries.lock
    const [isTeamAuth, isTournamentAuth] = await Promise.all([
      this.teamAuthRepo.can(tx, entry.teamId, 'team.tournament.enter'),
      this.tournamentAuthRepo.can(tx, tournamentId, 'tournament.entries.lock'),
    ]);

    if (!isTeamAuth && !isTournamentAuth) {
      throw TournamentError.forbidden(
        `Actor does not have authority to freeze squad for entry ${entryId}`,
        { entryId, actorId: principal.userId },
      );
    }

    // 6. Freeze squad
    const newRevision = await this.entryRepo.freezeSquad(tx, {
      entryId,
      expectedRevision: command.expectedRevision,
    });

    return {
      entryId,
      squadState: 'frozen',
      squadRevision: newRevision,
    };
  }
}
