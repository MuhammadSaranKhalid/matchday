import type { TournamentCommandContext, TournamentCommandHandler } from '../ports/tournament-command.ports.js';
import type {
  TeamAuthorizationRepository,
  TeamTournamentRepository,
  TournamentEntryRepository,
  TournamentRegistrationRepository,
  TournamentRootRepository,
} from '../ports/tournament-repository.ports.js';
import { TournamentError } from '../../domain/errors/tournament-error-codes.js';
import type {
  RegisterTeamCommand,
  RegisterTeamResult,
} from '../../domain/command/participation-commands.js';

export class RegisterTeamHandler
  implements TournamentCommandHandler<RegisterTeamCommand, RegisterTeamResult>
{
  constructor(
    private readonly rootRepo: TournamentRootRepository,
    private readonly registrationRepo: TournamentRegistrationRepository,
    private readonly entryRepo: TournamentEntryRepository,
    private readonly teamRepo: TeamTournamentRepository,
    private readonly teamAuthRepo: TeamAuthorizationRepository,
  ) {}

  async execute(
    context: TournamentCommandContext,
    command: RegisterTeamCommand,
  ): Promise<RegisterTeamResult> {
    const { tx, principal } = context;
    const tournamentId = command.resources.tournamentId!;
    const { teamId, message, squadProposal } = command.payload;

    // 1. Load and lock tournament root
    const tournament = await this.rootRepo.lockTournament(tx, tournamentId);

    // 2. Tournament must be in open registration state
    if (tournament.registrationState !== 'open') {
      throw TournamentError.invalidState(
        `Tournament registration is not open (state: ${tournament.registrationState})`,
        { tournamentId, registrationState: tournament.registrationState },
      );
    }

    // 3. Deadline check
    if (tournament.registrationDeadline) {
      const today = new Date().toISOString().split('T')[0]!;
      if (today > tournament.registrationDeadline) {
        throw TournamentError.invalidState(
          `Tournament registration deadline has passed (${tournament.registrationDeadline})`,
          { tournamentId, registrationDeadline: tournament.registrationDeadline },
        );
      }
    }

    // 4. Team must exist and sport must match
    const team = await this.teamRepo.findTeam(tx, teamId);
    if (!team) {
      throw TournamentError.notFound(`Team ${teamId} not found`, { teamId });
    }
    if (team.status !== 'active') {
      throw TournamentError.ruleViolation(`Team ${teamId} is not active`, {
        teamId,
        teamStatus: team.status,
      });
    }
    if (team.sportId !== tournament.sportId) {
      throw TournamentError.ruleViolation(
        `Team sport (${team.sportId}) does not match tournament sport (${tournament.sportId})`,
        { teamSport: team.sportId, tournamentSport: tournament.sportId },
      );
    }

    // 5. Actor must have team register permission
    await this.teamAuthRepo.require(tx, teamId, 'team.tournament.enter');

    // 6. No duplicate pending registration for this team
    const hasPending = await this.registrationRepo.hasPendingRegistration(
      tx,
      tournamentId,
      teamId,
    );
    if (hasPending) {
      throw TournamentError.conflict(
        `Team ${teamId} already has a pending registration for tournament ${tournamentId}`,
        { teamId, tournamentId },
      );
    }

    // 7. Capacity pre-check (soft guard — ApproveRegistration enforces hard)
    if (tournament.maxTeams !== null) {
      const activeCount = await this.entryRepo.countActiveEntries(tx, tournamentId);
      if (activeCount >= tournament.maxTeams) {
        throw TournamentError.capacityReached(
          `Tournament has reached maximum capacity of ${tournament.maxTeams} teams`,
          { tournamentId, maxTeams: tournament.maxTeams, activeEntries: activeCount },
        );
      }
    }

    // 8. Create registration
    const registrationId = await this.registrationRepo.createRegistration(tx, {
      tournamentId,
      teamId,
      registeredBy: principal.userId,
      message,
    });

    // 9. Create proposal members if squad proposal provided
    if (squadProposal && squadProposal.length > 0) {
      await this.registrationRepo.createProposalMembers(tx, {
        registrationId,
        tournamentId,
        teamId,
        submittedBy: principal.userId,
        members: squadProposal,
      });
    }

    return { registrationId, status: 'pending' };
  }
}
