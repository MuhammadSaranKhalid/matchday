import type { TournamentCommandContext, TournamentCommandHandler } from '../ports/tournament-command.ports.js';
import type {
  TeamAuthorizationRepository,
  TournamentAuthorizationRepository,
  TournamentRegistrationRepository,
} from '../ports/tournament-repository.ports.js';
import { TournamentError } from '../../domain/errors/tournament-error-codes.js';
import type {
  WithdrawPendingRegistrationCommand,
  WithdrawPendingRegistrationResult,
} from '../../domain/command/participation-commands.js';

export class WithdrawPendingRegistrationHandler
  implements
    TournamentCommandHandler<
      WithdrawPendingRegistrationCommand,
      WithdrawPendingRegistrationResult
    >
{
  constructor(
    private readonly tournamentAuthRepo: TournamentAuthorizationRepository,
    private readonly teamAuthRepo: TeamAuthorizationRepository,
    private readonly registrationRepo: TournamentRegistrationRepository,
  ) {}

  async execute(
    context: TournamentCommandContext,
    command: WithdrawPendingRegistrationCommand,
  ): Promise<WithdrawPendingRegistrationResult> {
    const { tx, principal } = context;
    const tournamentId = command.resources.tournamentId!;
    const registrationId = command.resources.registrationId!;

    // 1. Lock registration
    const registration = await this.registrationRepo.lockRegistration(tx, registrationId);

    // 2. Validate belongs to tournament
    if (registration.tournamentId !== tournamentId) {
      throw TournamentError.notFound(
        `Registration ${registrationId} does not belong to tournament ${tournamentId}`,
        { registrationId, tournamentId },
      );
    }

    // 3. Must be pending
    if (registration.status !== 'pending') {
      throw TournamentError.invalidState(
        `Cannot withdraw a registration with status '${registration.status}'. Only pending registrations can be withdrawn.`,
        { registrationId, status: registration.status },
      );
    }

    // 4. Authorization: actor must be a team authority OR have tournament registration.review capability
    const [isTeamAuth, isTournamentAuth] = await Promise.all([
      this.teamAuthRepo.can(tx, registration.teamId, 'team.tournament.enter'),
      this.tournamentAuthRepo.can(tx, tournamentId, 'tournament.registration.review'),
    ]);

    if (!isTeamAuth && !isTournamentAuth) {
      throw TournamentError.forbidden(
        `Actor does not have authority to withdraw registration ${registrationId}`,
        { registrationId, actorId: principal.userId },
      );
    }

    // 5. Withdraw registration
    await this.registrationRepo.withdrawRegistration(tx, {
      registrationId,
      withdrawnBy: principal.userId,
      withdrawalReason: command.payload.reason,
    });

    return { registrationId, status: 'withdrawn' };
  }
}
