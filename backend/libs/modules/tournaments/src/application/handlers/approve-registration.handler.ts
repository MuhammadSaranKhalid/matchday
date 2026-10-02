import type { TournamentCommandContext, TournamentCommandHandler } from '../ports/tournament-command.ports.js';
import type {
  TournamentAuthorizationRepository,
  TournamentEntryRepository,
  TournamentRegistrationRepository,
  TournamentRootRepository,
  TournamentSquadRepository,
} from '../ports/tournament-repository.ports.js';
import { TournamentError } from '../../domain/errors/tournament-error-codes.js';
import type {
  ApproveRegistrationCommand,
  ApproveRegistrationResult,
} from '../../domain/command/participation-commands.js';

export class ApproveRegistrationHandler
  implements TournamentCommandHandler<ApproveRegistrationCommand, ApproveRegistrationResult>
{
  constructor(
    private readonly rootRepo: TournamentRootRepository,
    private readonly tournamentAuthRepo: TournamentAuthorizationRepository,
    private readonly registrationRepo: TournamentRegistrationRepository,
    private readonly entryRepo: TournamentEntryRepository,
    private readonly squadRepo: TournamentSquadRepository,
  ) {}

  async execute(
    context: TournamentCommandContext,
    command: ApproveRegistrationCommand,
  ): Promise<ApproveRegistrationResult> {
    const { tx, principal } = context;
    const tournamentId = command.resources.tournamentId!;
    const registrationId = command.resources.registrationId!;

    // 1. Authorization: actor must have tournament.registration.review capability
    await this.tournamentAuthRepo.require(tx, tournamentId, 'tournament.registration.review');

    // 2. Lock registration
    const registration = await this.registrationRepo.lockRegistration(tx, registrationId);

    // 3. Validate registration belongs to this tournament
    if (registration.tournamentId !== tournamentId) {
      throw TournamentError.notFound(
        `Registration ${registrationId} does not belong to tournament ${tournamentId}`,
        { registrationId, tournamentId },
      );
    }

    // 4. Registration must be pending
    if (registration.status !== 'pending') {
      throw TournamentError.invalidState(
        `Cannot approve registration with status '${registration.status}'`,
        { registrationId, status: registration.status },
      );
    }

    // 5. No active entry for this team already
    const existingEntry = await this.entryRepo.findActiveEntryByTeam(
      tx,
      tournamentId,
      registration.teamId,
    );
    if (existingEntry) {
      throw TournamentError.conflict(
        `Team ${registration.teamId} already has an active entry in this tournament`,
        { teamId: registration.teamId, entryId: existingEntry.entryId },
      );
    }

    // 6. Hard capacity check: lock tournament root and verify
    const tournament = await this.rootRepo.lockTournament(tx, tournamentId);
    if (tournament.maxTeams !== null) {
      const activeCount = await this.entryRepo.countActiveEntries(tx, tournamentId);
      if (activeCount >= tournament.maxTeams) {
        throw TournamentError.capacityReached(
          `Tournament has reached maximum capacity of ${tournament.maxTeams} teams`,
          { tournamentId, maxTeams: tournament.maxTeams, activeEntries: activeCount },
        );
      }
    }

    // 7. Resolve registration as approved
    await this.registrationRepo.resolveRegistration(tx, {
      registrationId,
      status: 'approved',
      decidedBy: principal.userId,
    });

    // 8. Create entry
    const entry = await this.entryRepo.createEntry(tx, {
      tournamentId,
      teamId: registration.teamId,
      registrationId,
      acceptedBy: principal.userId,
      entrySource: 'application',
    });

    // 9. Materialize squad from proposal members
    const proposalMembers = await this.registrationRepo.getProposalMembers(tx, registrationId);
    if (proposalMembers.length > 0) {
      await this.squadRepo.materializeSquadFromProposal(tx, {
        entryId: entry.entryId,
        tournamentId,
        teamId: registration.teamId,
        addedBy: principal.userId,
        proposalMembers,
      });
    }

    return {
      registrationId,
      entryId: entry.entryId,
      entryRevision: tournament.entryRevision + 1,
    };
  }
}
