import type { TournamentCommandContext, TournamentCommandHandler } from '../ports/tournament-command.ports.js';
import type {
  TeamAuthorizationRepository,
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
    private readonly teamAuthRepo: TeamAuthorizationRepository,
    private readonly registrationRepo: TournamentRegistrationRepository,
  ) {}

  async execute(
    context: TournamentCommandContext,
    command: WithdrawPendingRegistrationCommand,
  ): Promise<WithdrawPendingRegistrationResult> {
    const { tx, principal } = context;
    const registrationId = command.resources.registrationId!;

    // 1. Lock registration first to derive authoritative team (Requirement 5)
    const registration = await this.registrationRepo.lockRegistration(tx, registrationId);

    // 2. Must be pending
    if (registration.status !== 'pending') {
      throw TournamentError.invalidState(
        `Cannot withdraw a registration with status '${registration.status}'. Only pending registrations can be withdrawn.`,
        { registrationId, status: registration.status },
      );
    }

    // 3. Authorization: actor must be a team authority (team.tournament.enter) (Requirement 16)
    await this.teamAuthRepo.require(tx, registration.teamId, 'team.tournament.enter');

    // 4. Withdraw registration
    await this.registrationRepo.withdrawRegistration(tx, {
      registrationId,
      withdrawnBy: principal.userId,
      withdrawalReason: command.payload.reason,
    });

    return { registrationId, status: 'withdrawn' };
  }
}
