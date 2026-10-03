import type { TournamentCommandContext, TournamentCommandHandler } from '../ports/tournament-command.ports.js';
import type {
  TeamAuthorizationRepository,
  TournamentEntryRepository,
  TournamentRootRepository,
  TournamentSquadRepository,
} from '../ports/tournament-repository.ports.js';
import { TournamentError } from '../../domain/errors/tournament-error-codes.js';
import { assertExpectedRevision } from '../../domain/revision/assert-expected-revision.js';
import type {
  WithdrawTournamentEntryCommand,
  WithdrawTournamentEntryResult,
} from '../../domain/command/participation-commands.js';

export class WithdrawTournamentEntryHandler
  implements
    TournamentCommandHandler<WithdrawTournamentEntryCommand, WithdrawTournamentEntryResult>
{
  constructor(
    private readonly rootRepo: TournamentRootRepository,
    private readonly teamAuthRepo: TeamAuthorizationRepository,
    private readonly entryRepo: TournamentEntryRepository,
    private readonly squadRepo: TournamentSquadRepository,
  ) {}

  async execute(
    context: TournamentCommandContext,
    command: WithdrawTournamentEntryCommand,
  ): Promise<WithdrawTournamentEntryResult> {
    const { tx, principal } = context;
    const entryId = command.resources.entryId!;

    // 1. Lock entry first to derive authoritative tournament and team (Requirement 5)
    const entry = await this.entryRepo.lockEntry(tx, entryId);
    const { tournamentId, teamId } = entry;

    // 2. Lock tournament root
    const tournament = await this.rootRepo.lockTournament(tx, tournamentId);

    // 3. Entry must be active
    if (entry.status !== 'active') {
      throw TournamentError.invalidState(
        `Cannot withdraw entry with status '${entry.status}'`,
        { entryId, status: entry.status },
      );
    }

    // 4. Tournament entry state must be editable (Requirement 18)
    if (tournament.entryState !== 'editable') {
      throw TournamentError.invalidState(
        `Cannot withdraw entry: tournament entry state is '${tournament.entryState}' (expected 'editable')`,
        { tournamentId, entryState: tournament.entryState },
      );
    }

    // 5. Authorization: actor must be team authority (team.tournament.enter) (Requirement 17)
    await this.teamAuthRepo.require(tx, teamId, 'team.tournament.enter');

    // 6. Optimistic concurrency control against tournament.entry_revision (Requirement 19)
    if (command.expectedRevision !== undefined) {
      assertExpectedRevision(command.expectedRevision, tournament.entryRevision);
    }

    // 7. Remove all active squad members (soft delete, preserves history) (Requirement 22)
    await this.squadRepo.removeAllActiveMembersForEntry(tx, {
      entryId,
      removedBy: principal.userId,
      removalReason: command.payload.reason ?? 'Entry withdrawn',
    });

    // 8. Withdraw the entry (DB trigger will increment tournaments.entry_revision)
    const withdrawn = await this.entryRepo.withdrawEntry(tx, {
      entryId,
      withdrawnBy: principal.userId,
      withdrawalReason: command.payload.reason,
    });

    // 9. Read actual resulting tournaments.entry_revision (Requirement 20)
    const updatedTournament = await this.rootRepo.findTournament(tx, tournamentId);
    const entryRevision = updatedTournament
      ? updatedTournament.entryRevision
      : tournament.entryRevision + 1;

    return {
      entryId: withdrawn.entryId,
      status: 'withdrawn',
      entryRevision,
    };
  }
}

