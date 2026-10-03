import type { TournamentCommandContext, TournamentCommandHandler } from '../ports/tournament-command.ports.js';
import type {
  TournamentAuthorizationRepository,
  TournamentEntryRepository,
} from '../ports/tournament-repository.ports.js';
import { TournamentError } from '../../domain/errors/tournament-error-codes.js';
import { assertExpectedRevision } from '../../domain/revision/assert-expected-revision.js';
import type {
  FreezeSquadCommand,
  FreezeSquadResult,
} from '../../domain/command/participation-commands.js';

export class FreezeSquadHandler
  implements TournamentCommandHandler<FreezeSquadCommand, FreezeSquadResult>
{
  constructor(
    private readonly tournamentAuthRepo: TournamentAuthorizationRepository,
    private readonly entryRepo: TournamentEntryRepository,
  ) {}

  async execute(
    context: TournamentCommandContext,
    command: FreezeSquadCommand,
  ): Promise<FreezeSquadResult> {
    const { tx, principal: _principal } = context;
    const entryId = command.resources.entryId!;

    // 1. Lock entry first to derive authoritative tournament (Requirement 5)
    const entry = await this.entryRepo.lockEntry(tx, entryId);
    const tournamentId = entry.tournamentId;

    // 2. Authorization: actor must have tournament.squad.review capability (Requirement 23)
    await this.tournamentAuthRepo.require(tx, tournamentId, 'tournament.squad.review');

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

    // 5. Concurrency check against entry.squad_revision before mutation (Requirement 24)
    const expectedRevision = command.expectedRevision;

    if (expectedRevision === undefined) {
      throw TournamentError.badRequest(
        'expectedRevision is required when freezing a Tournament squad',
        { entryId },
      );
    }

    assertExpectedRevision(
      expectedRevision,
      entry.squadRevision,
    );

    // 6. Freeze squad
    const newRevision = await this.entryRepo.freezeSquad(tx, {
      entryId,
      expectedRevision,
    });

    return {
      entryId,
      squadState: 'frozen',
      squadRevision: newRevision,
    };
  }
}

