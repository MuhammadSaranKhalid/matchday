import type { TournamentCommandContext, TournamentCommandHandler } from '../ports/tournament-command.ports.js';
import type {
  TeamAuthorizationRepository,
  TeamTournamentRepository,
  TournamentEntryRepository,
  TournamentRegistrationRepository,
  TournamentRootRepository,
  TournamentSquadRepository,
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
    private readonly squadRepo: TournamentSquadRepository,
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

    // 2. Tournament lifecycle check (Requirement 6)
    if (tournament.publicationState !== 'published') {
      throw TournamentError.invalidState(
        `Tournament is not published (publication_state: ${tournament.publicationState})`,
        { tournamentId, publicationState: tournament.publicationState },
      );
    }
    if (tournament.terminationState !== 'none') {
      throw TournamentError.invalidState(
        `Tournament is terminated (termination_state: ${tournament.terminationState})`,
        { tournamentId, terminationState: tournament.terminationState },
      );
    }
    if (tournament.registrationState !== 'open') {
      throw TournamentError.invalidState(
        `Tournament registration is not open (registration_state: ${tournament.registrationState})`,
        { tournamentId, registrationState: tournament.registrationState },
      );
    }

    // 3. Deadline check using PostgreSQL CURRENT_DATE (Requirement 7)
    if (tournament.registrationDeadline) {
      const deadlineRes = await tx.query<{ is_passed: boolean }>(
        'SELECT ($1::date < CURRENT_DATE) AS is_passed',
        [tournament.registrationDeadline],
      );
      if (deadlineRes.rows[0]?.is_passed) {
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

    // 6. Check team does not already have an active entry
    const existingEntry = await this.entryRepo.findActiveEntryByTeam(
      tx,
      tournamentId,
      teamId,
    );
    if (existingEntry) {
      throw TournamentError.conflict(
        `Team ${teamId} already has an active entry in tournament ${tournamentId}`,
        { teamId, tournamentId, entryId: existingEntry.entryId },
      );
    }

    // 7. No duplicate pending registration for this team
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

    // 8. Complete proposal prevalidation in NestJS (Requirement 10)
    if (squadProposal && squadProposal.length > 0) {
      const seenIdentities = new Set<string>();
      for (const member of squadProposal) {
        const hasUser = Boolean(member.userId);
        const hasUnclaimed = Boolean(member.unclaimedId);
        if ((hasUser && hasUnclaimed) || (!hasUser && !hasUnclaimed)) {
          throw TournamentError.badRequest(
            'Proposed squad member must specify exactly one of userId or unclaimedId',
            { member },
          );
        }
        const key = hasUser ? `user:${member.userId}` : `unclaimed:${member.unclaimedId}`;
        if (seenIdentities.has(key)) {
          throw TournamentError.badRequest(
            `Duplicate squad member in proposal: ${key}`,
            { member },
          );
        }
        seenIdentities.add(key);

        const isActiveMember = await this.squadRepo.isPlayerInActiveTeamRoster(
          tx,
          teamId,
          member,
        );
        if (!isActiveMember) {
          throw TournamentError.badRequest(
            `Proposed squad member is not an active member of team ${teamId}`,
            { member, teamId },
          );
        }
      }
    }

    // 9. Create registration
    const registrationId = await this.registrationRepo.createRegistration(tx, {
      tournamentId,
      teamId,
      registeredBy: principal.userId,
      message,
    });

    // 10. Create proposal members if squad proposal provided
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

