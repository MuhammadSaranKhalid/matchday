import type { TournamentCommandContext, TournamentCommandHandler } from '../ports/tournament-command.ports.js';
import type {
  TournamentAuthorizationRepository,
  TournamentRegistrationRepository,
} from '../ports/tournament-repository.ports.js';
import { TournamentError } from '../../domain/errors/tournament-error-codes.js';
import type {
  RejectRegistrationCommand,
  RejectRegistrationResult,
} from '../../domain/command/participation-commands.js';

export class RejectRegistrationHandler
  implements TournamentCommandHandler<RejectRegistrationCommand, RejectRegistrationResult>
{
  constructor(
    private readonly tournamentAuthRepo: TournamentAuthorizationRepository,
    private readonly registrationRepo: TournamentRegistrationRepository,
  ) {}

  async execute(
    context: TournamentCommandContext,
    command: RejectRegistrationCommand,
  ): Promise<RejectRegistrationResult> {
    const { tx, principal } = context;
    const tournamentId = command.resources.tournamentId!;
    const registrationId = command.resources.registrationId!;

    // 1. Authorization
    await this.tournamentAuthRepo.require(tx, tournamentId, 'tournament.registration.review');

    // 2. Lock registration
    const registration = await this.registrationRepo.lockRegistration(tx, registrationId);

    // 3. Validate belongs to tournament
    if (registration.tournamentId !== tournamentId) {
      throw TournamentError.notFound(
        `Registration ${registrationId} does not belong to tournament ${tournamentId}`,
        { registrationId, tournamentId },
      );
    }

    // 4. Must be pending
    if (registration.status !== 'pending') {
      throw TournamentError.invalidState(
        `Cannot reject registration with status '${registration.status}'`,
        { registrationId, status: registration.status },
      );
    }

    // 5. Resolve as rejected
    await this.registrationRepo.resolveRegistration(tx, {
      registrationId,
      status: 'rejected',
      decidedBy: principal.userId,
      decisionReason: command.payload.reason,
    });

    return { registrationId, status: 'rejected' };
  }
}
