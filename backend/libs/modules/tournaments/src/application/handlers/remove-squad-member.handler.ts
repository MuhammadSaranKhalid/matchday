import type { TournamentCommandContext, TournamentCommandHandler } from '../ports/tournament-command.ports.js';
import type {
  TeamAuthorizationRepository,
  TournamentEntryRepository,
  TournamentSquadRepository,
} from '../ports/tournament-repository.ports.js';
import { TournamentError } from '../../domain/errors/tournament-error-codes.js';
import { assertExpectedRevision } from '../../domain/revision/assert-expected-revision.js';
import type {
  RemoveSquadMemberCommand,
  RemoveSquadMemberResult,
} from '../../domain/command/participation-commands.js';

export class RemoveSquadMemberHandler
  implements TournamentCommandHandler<RemoveSquadMemberCommand, RemoveSquadMemberResult> {
  constructor(
    private readonly teamAuthRepo: TeamAuthorizationRepository,
    private readonly entryRepo: TournamentEntryRepository,
    private readonly squadRepo: TournamentSquadRepository,
  ) { }

  async execute(
    context: TournamentCommandContext,
    command: RemoveSquadMemberCommand,
  ): Promise<RemoveSquadMemberResult> {
    const { tx, principal } = context;
    const squadMemberId = command.resources.squadMemberId!;

    // 1. Lock squad member first (Requirement 26)
    const member = await this.squadRepo.lockSquadMember(tx, squadMemberId);
    if (member.membershipStatus !== 'active') {
      throw TournamentError.invalidState(
        `Cannot remove squad member with status '${member.membershipStatus}'`,
        { squadMemberId, status: member.membershipStatus },
      );
    }

    // 2. Lock entry from member.entryId
    const entry = await this.entryRepo.lockEntry(tx, member.entryId);

    // 3. Entry must be active
    if (entry.status !== 'active') {
      throw TournamentError.invalidState(
        `Cannot remove squad member from entry with status '${entry.status}'`,
        { entryId: entry.entryId, status: entry.status },
      );
    }

    // 4. Squad must be editable (Requirement 26 & 27)
    if (entry.squadState !== 'editable') {
      throw TournamentError.invalidState(
        `Cannot remove squad member: squad is frozen for entry ${entry.entryId}`,
        { entryId: entry.entryId, squadState: entry.squadState },
      );
    }

    // 5. Concurrency check against entry.squad_revision (Requirement 26)
    if (command.expectedRevision !== undefined) {
      assertExpectedRevision(command.expectedRevision, entry.squadRevision);
    }

    // 6. // Phase 6 v1 authority:
    // current Team tournament-entry authority also owns editable squad changes.
    // A distinct Team squad capability may be introduced later.
    await this.teamAuthRepo.require(
      tx,
      entry.teamId,
      'team.tournament.enter',
    );
    // 7. Soft-remove member (Requirement 22 & 26: do not DELETE)
    await this.squadRepo.removeSquadMember(tx, {
      squadMemberId,
      removedBy: principal.userId,
      removalReason: command.payload.reason,
    });

    // 8. Increment squad_revision once
    const newRevision = await this.entryRepo.bumpSquadRevision(tx, {
      entryId: entry.entryId,
    });

    return {
      squadMemberId,
      squadRevision: newRevision,
    };
  }
}
