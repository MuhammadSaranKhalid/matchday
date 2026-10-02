import { describe, expect, it, vi } from 'vitest';
import type { AuthenticatedPrincipal } from '@shared-kernel/identity/authenticated-principal.js';
import { TournamentCommandExecutor } from '../../../libs/modules/tournaments/src/application/command-executor/tournament-command-executor.js';
import type {
  CommandQueryExecutor,
  TournamentCommandHandler,
  TournamentTransactionExecutor,
} from '../../../libs/modules/tournaments/src/application/ports/tournament-command.ports.js';
import type {
  TournamentCommandReceiptRecord,
  TournamentCommandReceiptRepository,
} from '../../../libs/modules/tournaments/src/application/ports/tournament-repository.ports.js';
import type { TournamentCommand } from '../../../libs/modules/tournaments/src/domain/command/tournament-command.js';
import {
  TOURNAMENT_ERROR_CODES,
  TournamentError,
} from '../../../libs/modules/tournaments/src/domain/errors/tournament-error-codes.js';

describe('TournamentCommandExecutor (unit)', () => {
  const principalA: AuthenticatedPrincipal = {
    userId: '11111111-1111-4111-8111-111111111111',
    sessionId: 'session-a',
  };

  const principalB: AuthenticatedPrincipal = {
    userId: '22222222-2222-4222-8222-222222222222',
    sessionId: 'session-b',
  };

  const mockQueryExecutor: CommandQueryExecutor = {
    query: vi.fn().mockResolvedValue({ rows: [], rowCount: 0 }),
  };

  const fakeTxExecutor: TournamentTransactionExecutor = {
    withCommandTransaction: vi.fn(async (_principal, work) => work(mockQueryExecutor)),
  };

  function createMockReceiptRepo(): TournamentCommandReceiptRepository {
    const receipts = new Map<string, TournamentCommandReceiptRecord>();
    return {
      findReceipt: vi.fn(async (_tx, commandId) => receipts.get(commandId) ?? null),
      saveReceipt: vi.fn(async (_tx, receipt) => {
        receipts.set(receipt.commandId, {
          ...receipt,
          tournamentId: receipt.tournamentId ?? null,
          createdAt: new Date(),
          completedAt: new Date(),
        });
      }),
    };
  }

  it('rejects command with missing or empty commandId', async () => {
    const receiptRepo = createMockReceiptRepo();
    const executor = new TournamentCommandExecutor(fakeTxExecutor, receiptRepo);

    const invalidCmd = {
      commandId: '',
      action: 'test_action',
      resources: {},
      payload: {},
    } as unknown as TournamentCommand;

    const handler: TournamentCommandHandler<TournamentCommand, { ok: boolean }> = {
      execute: vi.fn(),
    };

    await expect(executor.execute(principalA, invalidCmd, handler)).rejects.toThrow(
      TournamentError,
    );
  });

  it('executes handler and saves receipt on first invocation', async () => {
    const receiptRepo = createMockReceiptRepo();
    const executor = new TournamentCommandExecutor(fakeTxExecutor, receiptRepo);

    const cmd: TournamentCommand<{ name: string }> = {
      commandId: 'cmd-uuid-1',
      action: 'create_sample',
      resources: { tournamentId: 'tourn-1' },
      expectedRevision: 1,
      payload: { name: 'Championship' },
    };

    const handler: TournamentCommandHandler<typeof cmd, { created: boolean }> = {
      execute: vi.fn().mockResolvedValue({ created: true }),
    };

    const outcome = await executor.execute(principalA, cmd, handler);

    expect(outcome.status).toBe('executed');
    expect(outcome.result).toEqual({ created: true });
    expect(handler.execute).toHaveBeenCalledTimes(1);
    expect(receiptRepo.saveReceipt).toHaveBeenCalledTimes(1);
  });

  it('replays original response without calling handler again on duplicate submission', async () => {
    const receiptRepo = createMockReceiptRepo();
    const executor = new TournamentCommandExecutor(fakeTxExecutor, receiptRepo);

    const cmd: TournamentCommand<{ name: string }> = {
      commandId: 'cmd-uuid-2',
      action: 'create_sample',
      resources: { tournamentId: 'tourn-1' },
      expectedRevision: 1,
      payload: { name: 'Championship' },
    };

    let executionCount = 0;
    const handler: TournamentCommandHandler<typeof cmd, { executionNumber: number }> = {
      execute: vi.fn(async () => {
        executionCount += 1;
        return { executionNumber: executionCount };
      }),
    };

    // First call
    const first = await executor.execute(principalA, cmd, handler);
    expect(first.status).toBe('executed');
    expect(first.result).toEqual({ executionNumber: 1 });

    // Second call with same commandId and payload
    const second = await executor.execute(principalA, cmd, handler);
    expect(second.status).toBe('replayed');
    expect(second.result).toEqual({ executionNumber: 1 }); // Cached result!
    expect(handler.execute).toHaveBeenCalledTimes(1); // Not called again!
  });

  it('throws IDEMPOTENCY_CONFLICT when another actor tries to reuse the same commandId', async () => {
    const receiptRepo = createMockReceiptRepo();
    const executor = new TournamentCommandExecutor(fakeTxExecutor, receiptRepo);

    const cmd: TournamentCommand = {
      commandId: 'shared-cmd-id',
      action: 'some_action',
      resources: {},
      payload: {},
    };

    const handler: TournamentCommandHandler<TournamentCommand, { success: boolean }> = {
      execute: vi.fn().mockResolvedValue({ success: true }),
    };

    // User A executes successfully
    await executor.execute(principalA, cmd, handler);

    // User B tries same commandId
    await expect(executor.execute(principalB, cmd, handler)).rejects.toThrow(
      expect.objectContaining({
        code: TOURNAMENT_ERROR_CODES.IDEMPOTENCY_CONFLICT,
      }),
    );
  });

  it('throws IDEMPOTENCY_CONFLICT when same actor provides different semantic payload for same commandId', async () => {
    const receiptRepo = createMockReceiptRepo();
    const executor = new TournamentCommandExecutor(fakeTxExecutor, receiptRepo);

    const cmd1: TournamentCommand<{ count: number }> = {
      commandId: 'same-cmd-id',
      action: 'increment',
      resources: { tournamentId: 'tourn-1' },
      payload: { count: 1 },
    };

    const cmd2: TournamentCommand<{ count: number }> = {
      commandId: 'same-cmd-id',
      action: 'increment',
      resources: { tournamentId: 'tourn-1' },
      payload: { count: 2 }, // Different payload!
    };

    const handler: TournamentCommandHandler<typeof cmd1, { count: number }> = {
      execute: vi.fn(async (_ctx, c) => ({ count: c.payload.count })),
    };

    await executor.execute(principalA, cmd1, handler);

    await expect(executor.execute(principalA, cmd2, handler)).rejects.toThrow(
      expect.objectContaining({
        code: TOURNAMENT_ERROR_CODES.IDEMPOTENCY_CONFLICT,
      }),
    );
  });
});
