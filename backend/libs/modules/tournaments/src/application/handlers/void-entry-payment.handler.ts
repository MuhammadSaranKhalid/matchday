import type { TournamentCommandContext, TournamentCommandHandler } from '../ports/tournament-command.ports.js';
import type {
  TournamentAuthorizationRepository,
  TournamentEntryRepository,
  TournamentPaymentRepository,
} from '../ports/tournament-repository.ports.js';
import { TournamentError } from '../../domain/errors/tournament-error-codes.js';
import type {
  VoidEntryPaymentCommand,
  VoidEntryPaymentResult,
} from '../../domain/command/participation-commands.js';

export class VoidEntryPaymentHandler
  implements TournamentCommandHandler<VoidEntryPaymentCommand, VoidEntryPaymentResult>
{
  constructor(
    private readonly tournamentAuthRepo: TournamentAuthorizationRepository,
    private readonly entryRepo: TournamentEntryRepository,
    private readonly paymentRepo: TournamentPaymentRepository,
  ) {}

  async execute(
    context: TournamentCommandContext,
    command: VoidEntryPaymentCommand,
  ): Promise<VoidEntryPaymentResult> {
    const { tx, principal } = context;
    const paymentId = command.resources.paymentId!;
    const { voidReason } = command.payload;

    // 1. Lock payment first (Requirement 30)
    const payment = await this.paymentRepo.lockPayment(tx, paymentId);
    if (payment.isVoid) {
      throw TournamentError.invalidState(`Payment ${paymentId} is already voided`, {
        paymentId,
      });
    }

    // 2. Lock parent Entry (primary serialization lock boundary, Requirement 29)
    const entry = await this.entryRepo.lockEntry(tx, payment.entryId);
    const tournamentId = entry.tournamentId;

    // 3. Authorize tournament payment manager capability (Requirement 26 & 30)
    await this.tournamentAuthRepo.require(tx, tournamentId, 'tournament.payment.manage');

    // 4. Validate non-empty reason
    if (!voidReason || voidReason.trim().length === 0) {
      throw TournamentError.badRequest('Void reason is required', { paymentId });
    }

    // 5. Void payment (Requirement 30: stamps void metadata, never DELETE)
    await this.paymentRepo.voidPayment(tx, {
      paymentId,
      voidedBy: principal.userId,
      voidReason: voidReason.trim(),
    });

    return {
      paymentId,
      isVoid: true,
    };
  }
}
