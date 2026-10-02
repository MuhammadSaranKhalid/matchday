import type { AuthenticatedPrincipal } from '@shared-kernel/identity/authenticated-principal.js';
import { computeRequestFingerprint } from '../../domain/command/fingerprint.js';
import type { TournamentCommand } from '../../domain/command/tournament-command.js';
import { TournamentError } from '../../domain/errors/tournament-error-codes.js';
import type {
  TournamentCommandContext,
  TournamentCommandExecutionResult,
  TournamentCommandHandler,
  TournamentTransactionExecutor,
} from '../ports/tournament-command.ports.js';
import type { TournamentCommandReceiptRepository } from '../ports/tournament-repository.ports.js';

export class TournamentCommandExecutor {
  constructor(
    private readonly transactionExecutor: TournamentTransactionExecutor,
    private readonly receiptRepository: TournamentCommandReceiptRepository,
  ) {}

  async execute<C extends TournamentCommand<TPayload>, R, TPayload = unknown>(
    principal: AuthenticatedPrincipal,
    command: C,
    handler: TournamentCommandHandler<C, R>,
  ): Promise<TournamentCommandExecutionResult<R>> {
    if (!command.commandId || typeof command.commandId !== 'string') {
      throw TournamentError.badRequest('Command ID is required and must be a valid string');
    }

    const fingerprint = computeRequestFingerprint(command);

    return this.transactionExecutor.withCommandTransaction(principal, async (tx) => {
      // 1. Fast-path: Check for already committed receipt before acquiring lock
      const earlyReceipt = await this.receiptRepository.findReceipt(tx, command.commandId);
      if (earlyReceipt) {
        return this.resolveExistingReceipt(earlyReceipt, principal, command, fingerprint);
      }

      // 2. Transaction-scoped advisory lock on commandId
      // Uses PostgreSQL's deterministic hashtext() function (32-bit signed integer promoted to bigint).
      // pg_advisory_xact_lock releases automatically on COMMIT or ROLLBACK, preventing pool leaks.
      // Hash collisions may conservatively serialize unrelated commands, but cannot corrupt idempotency
      // because private.tournament_command_receipts primary key remains authoritative.
      await tx.query('select pg_advisory_xact_lock(hashtext($1))', [command.commandId]);

      // 3. Mandatory RE-CHECK: After waiting on the lock, another concurrent transaction may have committed
      const existingReceipt = await this.receiptRepository.findReceipt(tx, command.commandId);
      if (existingReceipt) {
        return this.resolveExistingReceipt(existingReceipt, principal, command, fingerprint);
      }

      // 2. Fresh execution
      const context: TournamentCommandContext = {
        tx,
        principal,
        commandId: command.commandId,
      };

      const result = await handler.execute(context, command);

      // 3. Atomically persist receipt in same transaction
      await this.receiptRepository.saveReceipt(tx, {
        commandId: command.commandId,
        actorId: principal.userId,
        action: command.action,
        tournamentId: command.resources.tournamentId ?? null,
        requestFingerprint: fingerprint,
        responsePayload: result,
      });

      return {
        result,
        status: 'executed',
      };
    });
  }

  private resolveExistingReceipt<C extends TournamentCommand<unknown>, R>(
    existingReceipt: {
      actorId: string;
      action: string;
      requestFingerprint: string;
      responsePayload: unknown;
    },
    principal: AuthenticatedPrincipal,
    command: C,
    fingerprint: string,
  ): TournamentCommandExecutionResult<R> {
    // 1. Enforce actor isolation
    if (existingReceipt.actorId !== principal.userId) {
      throw TournamentError.idempotencyConflict(
        'Command ID was previously used by a different actor',
        { commandId: command.commandId },
      );
    }

    // 2. Enforce semantic equivalence (action + fingerprint which includes resources, payload, expectedRevision)
    if (
      existingReceipt.action !== command.action ||
      existingReceipt.requestFingerprint !== fingerprint
    ) {
      throw TournamentError.idempotencyConflict(
        'Command ID was previously used with different command parameters',
        { commandId: command.commandId },
      );
    }

    // 3. Replay original response
    return {
      result: existingReceipt.responsePayload as R,
      status: 'replayed',
    };
  }
}

