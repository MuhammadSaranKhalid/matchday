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
    const registrationId = command.resources.registrationId!;

    // 1. Lock registration first to derive authoritative tournament and team (Requirement 5)
    const registration = await this.registrationRepo.lockRegistration(tx, registrationId);
    const { tournamentId, teamId } = registration;

    // 2. Lock tournament root
    const tournament = await this.rootRepo.lockTournament(tx, tournamentId);

    // 3. Authorize against derived tournament (Requirement 5)
    await this.tournamentAuthRepo.require(tx, tournamentId, 'tournament.registration.review');

    // 4. Registration must be pending
    if (registration.status !== 'pending') {
      throw TournamentError.invalidState(
        `Cannot approve registration with status '${registration.status}'`,
        { registrationId, status: registration.status },
      );
    }

    // 5. Tournament entry set must be editable (Requirement 11)
    if (tournament.entryState !== 'editable') {
      throw TournamentError.invalidState(
        `Cannot approve registration: tournament entry state is '${tournament.entryState}' (expected 'editable')`,
        { tournamentId, entryState: tournament.entryState },
      );
    }

    // 6. No active entry for this team already
    const existingEntry = await this.entryRepo.findActiveEntryByTeam(
      tx,
      tournamentId,
      teamId,
    );
    if (existingEntry) {
      throw TournamentError.conflict(
        `Team ${teamId} already has an active entry in this tournament`,
        { teamId, entryId: existingEntry.entryId },
      );
    }

    // 7. Hard capacity check: with tournament root locked (Requirement 12)
    if (tournament.maxTeams !== null) {
      const activeCount = await this.entryRepo.countActiveEntries(tx, tournamentId);
      if (activeCount >= tournament.maxTeams) {
        throw TournamentError.capacityReached(
          `Tournament has reached maximum capacity of ${tournament.maxTeams} teams`,
          { tournamentId, maxTeams: tournament.maxTeams, activeEntries: activeCount },
        );
      }
    }

    // 8. Prevalidate the entire squad proposal before mutation (Requirement 13)
    const proposalMembers = await this.registrationRepo.getProposalMembers(tx, registrationId);
    for (const member of proposalMembers) {
      const player = {
        userId: member.userId ?? undefined,
        unclaimedId: member.unclaimedId ?? undefined,
      };

      // Must still be active on team roster
      const isRosterActive = await this.squadRepo.isPlayerInActiveTeamRoster(tx, teamId, player);
      if (!isRosterActive) {
        throw TournamentError.ruleViolation(
          `Proposed squad member is no longer an active member of team ${teamId}`,
          { teamId, member },
        );
      }

      // Must not be active in another team's squad in this tournament
      const inOtherSquad = await this.squadRepo.isPlayerInActiveTournamentSquad(
        tx,
        tournamentId,
        player,
      );
      if (inOtherSquad) {
        throw TournamentError.conflict(
          `Proposed squad member is already active in another team squad for this tournament`,
          { tournamentId, member },
        );
      }
    }

    // 9. Resolve registration as approved
    await this.registrationRepo.resolveRegistration(tx, {
      registrationId,
      status: 'approved',
      decidedBy: principal.userId,
    });

    // 10. Create entry
    const entry = await this.entryRepo.createEntry(tx, {
      tournamentId,
      teamId,
      registrationId,
      acceptedBy: principal.userId,
      entrySource: 'application',
    });

    // 11. Materialize squad from proposal members (Requirement 14: no silent omission)
    if (proposalMembers.length > 0) {
      await this.squadRepo.materializeSquadFromProposal(tx, {
        entryId: entry.entryId,
        tournamentId,
        teamId,
        addedBy: principal.userId,
        proposalMembers,
      });
    }

    // 12. Query actual resulting entry_revision from DB trigger (Requirement 15)
    const updatedTournament = await this.rootRepo.findTournament(tx, tournamentId);
    const entryRevision = updatedTournament
      ? updatedTournament.entryRevision
      : tournament.entryRevision + 1;

    return {
      registrationId,
      entryId: entry.entryId,
      entryRevision,
    };
  }
}
