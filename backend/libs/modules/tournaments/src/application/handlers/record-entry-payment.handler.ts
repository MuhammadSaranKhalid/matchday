import type { TournamentCommandContext, TournamentCommandHandler } from '../ports/tournament-command.ports.js';
import type {
  TournamentAuthorizationRepository,
  TournamentEntryRepository,
  TournamentPaymentRepository,
  TournamentRootRepository,
} from '../ports/tournament-repository.ports.js';
import { TournamentError } from '../../domain/errors/tournament-error-codes.js';
import type {
  RecordEntryPaymentCommand,
  RecordEntryPaymentResult,
} from '../../domain/command/participation-commands.js';

export class RecordEntryPaymentHandler
  implements TournamentCommandHandler<RecordEntryPaymentCommand, RecordEntryPaymentResult>
{
  constructor(
    private readonly rootRepo: TournamentRootRepository,
    private readonly tournamentAuthRepo: TournamentAuthorizationRepository,
    private readonly entryRepo: TournamentEntryRepository,
    private readonly paymentRepo: TournamentPaymentRepository,
  ) {}

  async execute(
    context: TournamentCommandContext,
    command: RecordEntryPaymentCommand,
  ): Promise<RecordEntryPaymentResult> {
    const { tx, principal } = context;
    const entryId = command.resources.entryId!;
    const { amount, paymentChannel, paymentReference, notes } = command.payload;

    // 1. Lock Entry as primary serialization lock boundary (Requirement 29)
    const entry = await this.entryRepo.lockEntry(tx, entryId);
    const tournamentId = entry.tournamentId;

    // 2. Authorize tournament payment manager capability (Requirement 28)
    await this.tournamentAuthRepo.require(tx, tournamentId, 'tournament.payment.manage');

    // 3. Amount must be positive
    if (amount <= 0) {
      throw TournamentError.badRequest('Payment amount must be greater than zero', {
        amount,
      });
    }

    // 4. Overpayment check against tournament entry fee (Requirement 28)
    const currentTotal = await this.paymentRepo.getEntryNonVoidedTotal(tx, entryId);
    const tournament = await this.rootRepo.findTournament(tx, tournamentId);
    if (tournament && tournament.entryFee > 0) {
      if (currentTotal + amount > tournament.entryFee) {
        throw TournamentError.badRequest(
          `Payment amount (${amount}) exceeds outstanding fee balance (${tournament.entryFee - currentTotal})`,
          {
            entryFee: tournament.entryFee,
            currentTotal,
            attemptedAmount: amount,
            outstanding: tournament.entryFee - currentTotal,
          },
        );
      }
    }

    // 5. Append payment row (Requirement 25: append-only payment events)
    const paymentId = await this.paymentRepo.createPayment(tx, {
      entryId,
      tournamentId,
      amount,
      paymentChannel,
      paymentReference,
      notes,
      recordedBy: principal.userId,
    });

    return {
      paymentId,
      entryId,
      amount,
    };
  }
}
