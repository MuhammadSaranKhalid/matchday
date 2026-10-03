import type { TournamentCommandContext, TournamentCommandHandler } from '../ports/tournament-command.ports.js';
import type {
  TeamAuthorizationRepository,
  TournamentEntryRepository,
  TournamentSquadRepository,
} from '../ports/tournament-repository.ports.js';
import { TournamentError } from '../../domain/errors/tournament-error-codes.js';
import { assertExpectedRevision } from '../../domain/revision/assert-expected-revision.js';
import type {
  AddSquadMemberCommand,
  AddSquadMemberResult,
} from '../../domain/command/participation-commands.js';

export class AddSquadMemberHandler
  implements TournamentCommandHandler<AddSquadMemberCommand, AddSquadMemberResult> {
  constructor(
    private readonly teamAuthRepo: TeamAuthorizationRepository,
    private readonly entryRepo: TournamentEntryRepository,
    private readonly squadRepo: TournamentSquadRepository,
  ) { }

  async execute(
    context: TournamentCommandContext,
    command: AddSquadMemberCommand,
  ): Promise<AddSquadMemberResult> {
    const { tx, principal } = context;
    const entryId = command.resources.entryId!;

    // 1. Lock entry to derive authoritative tournament and team (Requirement 5)
    const entry = await this.entryRepo.lockEntry(tx, entryId);
    const { tournamentId, teamId } = entry;

    // 2. Entry must be active
    if (entry.status !== 'active') {
      throw TournamentError.invalidState(
        `Cannot add squad member to entry with status '${entry.status}'`,
        { entryId, status: entry.status },
      );
    }

    // 3. Squad must be editable (Requirement 25 & 27)
    if (entry.squadState !== 'editable') {
      throw TournamentError.invalidState(
        `Cannot add squad member: squad is frozen for entry ${entryId}`,
        { entryId, squadState: entry.squadState },
      );
    }

    // 4. Concurrency check against entry.squad_revision (Requirement 25)
    const expectedRevision = command.expectedRevision;

    if (expectedRevision === undefined) {
      throw TournamentError.badRequest(
        'expectedRevision is required when adding a Tournament squad member',
        { entryId },
      );
    }

    assertExpectedRevision(
      expectedRevision,
      entry.squadRevision,
    );

    // 5. // Phase 6 v1 authority:
// current Team tournament-entry authority also owns editable squad changes.
// A distinct Team squad capability may be introduced later.
    await this.teamAuthRepo.require(
      tx,
      teamId,
      'team.tournament.enter',
    );
    // 6. Identity validation (strict XOR)
    const { userId, unclaimedId } = command.payload;
    const hasUser = Boolean(userId);
    const hasUnclaimed = Boolean(unclaimedId);
    if ((hasUser && hasUnclaimed) || (!hasUser && !hasUnclaimed)) {
      throw TournamentError.badRequest(
        'Squad member must specify exactly one of userId or unclaimedId',
        { userId, unclaimedId },
      );
    }
    const player = { userId, unclaimedId };

    // 7. Player must be an active member of the team roster
    const isRosterActive = await this.squadRepo.isPlayerInActiveTeamRoster(tx, teamId, player);
    if (!isRosterActive) {
      throw TournamentError.badRequest(
        `Player is not an active member of team ${teamId}`,
        { teamId, player },
      );
    }

    // 8. Player must not be active in another entry or already active in this entry
    const isAlreadyActiveInTournament = await this.squadRepo.isPlayerInActiveTournamentSquad(
      tx,
      tournamentId,
      player,
    );
    if (isAlreadyActiveInTournament) {
      const inOtherEntry = await this.squadRepo.isPlayerInActiveTournamentSquad(
        tx,
        tournamentId,
        player,
        entryId,
      );
      if (inOtherEntry) {
        throw TournamentError.conflict(
          `Player is already active in another team squad for tournament ${tournamentId}`,
          { tournamentId, player },
        );
      }
      throw TournamentError.conflict(
        `Player is already an active member of squad for entry ${entryId}`,
        { entryId, player },
      );
    }

    // 9. Add or reactivate squad member
    const squadMemberId = await this.squadRepo.addOrReactivateSquadMember(tx, {
      entryId,
      tournamentId,
      player,
      addedBy: principal.userId,
    });

    // 10. Bump squad revision on entry (Requirement 25: squad_revision += 1 exactly once)
    const newRevision = await this.entryRepo.bumpSquadRevision(tx, {
      entryId,
      expectedRevision,
    });

    return {
      squadMemberId,
      squadRevision: newRevision,
    };
  }
}
