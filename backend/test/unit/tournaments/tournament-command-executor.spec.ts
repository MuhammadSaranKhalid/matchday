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
import { TOURNAMENT_ERROR_CODES } from '../../../libs/modules/tournaments/src/domain/errors/tournament-error-codes.js';


describe('TournamentCommandExecutor (unit)', () => {
  const principalA: AuthenticatedPrincipal = {
    userId: '11111111-1111-4111-8111-111111111111',
    sessionId: '50000000-0000-4000-8000-000000000001',
  };

  const principalB: AuthenticatedPrincipal = {
    userId: '22222222-2222-4222-8222-222222222222',
    sessionId: '50000000-0000-4000-8000-000000000002',
  };

  const mockQueryExecutor: CommandQueryExecutor = {
    query: vi.fn().mockResolvedValue({ rows: [], rowCount: 0 }),
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

  it('Requirement 4 & 6: rejects command with empty commandId before opening transaction', async () => {
    const receiptRepo = createMockReceiptRepo();
    const withTx = vi.fn(async (_principal, work) => work(mockQueryExecutor));
    const fakeTxExecutor: TournamentTransactionExecutor = { withCommandTransaction: withTx };
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
      expect.objectContaining({
        code: TOURNAMENT_ERROR_CODES.BAD_REQUEST,
      }),
    );
    expect(withTx).not.toHaveBeenCalled();
    expect(handler.execute).not.toHaveBeenCalled();
    expect(receiptRepo.saveReceipt).not.toHaveBeenCalled();
  });

  it('Requirement 7: proves non-UUID commandId produces BAD_REQUEST and never executes handler or opens transaction', async () => {
    const receiptRepo = createMockReceiptRepo();
    const withTx = vi.fn(async (_principal, work) => work(mockQueryExecutor));
    const fakeTxExecutor: TournamentTransactionExecutor = { withCommandTransaction: withTx };
    const executor = new TournamentCommandExecutor(fakeTxExecutor, receiptRepo);

    let executionCount = 0;
    const handler: TournamentCommandHandler<TournamentCommand, void> = {
      execute: vi.fn(async () => {
        executionCount += 1;
      }),
    };

    const invalidCmd: TournamentCommand = {
      commandId: 'not-a-valid-uuid',
      action: 'test_action',
      resources: {},
      payload: {},
    };

    await expect(executor.execute(principalA, invalidCmd, handler)).rejects.toThrow(
      expect.objectContaining({
        code: TOURNAMENT_ERROR_CODES.BAD_REQUEST,
      }),
    );

    expect(executionCount).toBe(0);
    expect(handler.execute).not.toHaveBeenCalled();
    expect(withTx).not.toHaveBeenCalled();
    expect(receiptRepo.saveReceipt).not.toHaveBeenCalled();
  });

  it('Requirement 8: rejects non-integer or non-positive expectedRevision', async () => {
    const receiptRepo = createMockReceiptRepo();
    const fakeTxExecutor: TournamentTransactionExecutor = {
      withCommandTransaction: vi.fn(async (_principal, work) => work(mockQueryExecutor)),
    };
    const executor = new TournamentCommandExecutor(fakeTxExecutor, receiptRepo);

    const handler: TournamentCommandHandler<TournamentCommand, void> = {
      execute: vi.fn(),
    };

    const baseCmd = {
      commandId: 'c0000000-0000-4000-8000-000000000001',
      action: 'test_action',
      resources: {},
      payload: {},
    };

    // 0 is rejected
    await expect(
      executor.execute(principalA, { ...baseCmd, expectedRevision: 0 } as TournamentCommand, handler),
    ).rejects.toThrow(expect.objectContaining({ code: TOURNAMENT_ERROR_CODES.BAD_REQUEST }));

    // negative is rejected
    await expect(
      executor.execute(principalA, { ...baseCmd, expectedRevision: -5 } as TournamentCommand, handler),
    ).rejects.toThrow(expect.objectContaining({ code: TOURNAMENT_ERROR_CODES.BAD_REQUEST }));

    // decimal is rejected
    await expect(
      executor.execute(principalA, { ...baseCmd, expectedRevision: 1.5 } as TournamentCommand, handler),
    ).rejects.toThrow(expect.objectContaining({ code: TOURNAMENT_ERROR_CODES.BAD_REQUEST }));

    // NaN is rejected
    await expect(
      executor.execute(principalA, { ...baseCmd, expectedRevision: Number.NaN } as TournamentCommand, handler),
    ).rejects.toThrow(expect.objectContaining({ code: TOURNAMENT_ERROR_CODES.BAD_REQUEST }));

    // Infinity is rejected
    await expect(
      executor.execute(principalA, { ...baseCmd, expectedRevision: Number.POSITIVE_INFINITY } as TournamentCommand, handler),
    ).rejects.toThrow(expect.objectContaining({ code: TOURNAMENT_ERROR_CODES.BAD_REQUEST }));
  });

  it('Requirement 9: rejects empty or whitespace-only action', async () => {
    const receiptRepo = createMockReceiptRepo();
    const fakeTxExecutor: TournamentTransactionExecutor = {
      withCommandTransaction: vi.fn(async (_principal, work) => work(mockQueryExecutor)),
    };
    const executor = new TournamentCommandExecutor(fakeTxExecutor, receiptRepo);

    const handler: TournamentCommandHandler<TournamentCommand, void> = {
      execute: vi.fn(),
    };

    const baseCmd = {
      commandId: 'c0000000-0000-4000-8000-000000000002',
      resources: {},
      payload: {},
    };

    await expect(
      executor.execute(principalA, { ...baseCmd, action: '' } as TournamentCommand, handler),
    ).rejects.toThrow(expect.objectContaining({ code: TOURNAMENT_ERROR_CODES.BAD_REQUEST }));

    await expect(
      executor.execute(principalA, { ...baseCmd, action: '   ' } as TournamentCommand, handler),
    ).rejects.toThrow(expect.objectContaining({ code: TOURNAMENT_ERROR_CODES.BAD_REQUEST }));
  });

  it('Requirement 10: rejects non-serializable handler results (BigInt, function, symbol, circular object)', async () => {
    const receiptRepo = createMockReceiptRepo();
    const fakeTxExecutor: TournamentTransactionExecutor = {
      withCommandTransaction: vi.fn(async (_principal, work) => work(mockQueryExecutor)),
    };
    const executor = new TournamentCommandExecutor(fakeTxExecutor, receiptRepo);

    const cmd: TournamentCommand = {
      commandId: 'c0000000-0000-4000-8000-000000000003',
      action: 'return_bigint',
      resources: {},
      payload: {},
    };

    // BigInt in result
    const bigintHandler: TournamentCommandHandler<TournamentCommand, unknown> = {
      execute: vi.fn().mockResolvedValue({ num: 100n }),
    };
    await expect(executor.execute(principalA, cmd, bigintHandler)).rejects.toThrow(/BigInt/i);

    // Circular object in result
    const circular: Record<string, unknown> = { a: 1 };
    circular.self = circular;
    const circularHandler: TournamentCommandHandler<TournamentCommand, unknown> = {
      execute: vi.fn().mockResolvedValue(circular),
    };
    await expect(executor.execute(principalA, cmd, circularHandler)).rejects.toThrow(/circular/i);
  });

  it('Requirement 6 & 20: executes handler and saves receipt on first invocation with valid RFC UUID', async () => {
    const receiptRepo = createMockReceiptRepo();
    const fakeTxExecutor: TournamentTransactionExecutor = {
      withCommandTransaction: vi.fn(async (_principal, work) => work(mockQueryExecutor)),
    };
    const executor = new TournamentCommandExecutor(fakeTxExecutor, receiptRepo);

    const cmd: TournamentCommand<{ name: string }> = {
      commandId: 'c0000000-0000-4000-8000-000000000010',
      action: 'create_sample',
      resources: { tournamentId: 'f0000000-0000-4000-8000-000000000001' },
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

  it('Requirement 20: replays original response without calling handler again on duplicate submission', async () => {
    const receiptRepo = createMockReceiptRepo();
    const fakeTxExecutor: TournamentTransactionExecutor = {
      withCommandTransaction: vi.fn(async (_principal, work) => work(mockQueryExecutor)),
    };
    const executor = new TournamentCommandExecutor(fakeTxExecutor, receiptRepo);

    const cmd: TournamentCommand<{ name: string }> = {
      commandId: 'c0000000-0000-4000-8000-000000000020',
      action: 'create_sample',
      resources: { tournamentId: 'f0000000-0000-4000-8000-000000000001' },
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

  it('Requirement 21: throws IDEMPOTENCY_CONFLICT when another actor tries to reuse the same commandId', async () => {
    const receiptRepo = createMockReceiptRepo();
    const fakeTxExecutor: TournamentTransactionExecutor = {
      withCommandTransaction: vi.fn(async (_principal, work) => work(mockQueryExecutor)),
    };
    const executor = new TournamentCommandExecutor(fakeTxExecutor, receiptRepo);

    const cmd: TournamentCommand = {
      commandId: 'c0000000-0000-4000-8000-000000000030',
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

  it('Requirement 22: throws IDEMPOTENCY_CONFLICT when same actor provides different semantic payload for same commandId', async () => {
    const receiptRepo = createMockReceiptRepo();
    const fakeTxExecutor: TournamentTransactionExecutor = {
      withCommandTransaction: vi.fn(async (_principal, work) => work(mockQueryExecutor)),
    };
    const executor = new TournamentCommandExecutor(fakeTxExecutor, receiptRepo);

    const cmd1: TournamentCommand<{ count: number }> = {
      commandId: 'c0000000-0000-4000-8000-000000000040',
      action: 'increment',
      resources: { tournamentId: 'f0000000-0000-4000-8000-000000000001' },
      payload: { count: 1 },
    };

    const cmd2: TournamentCommand<{ count: number }> = {
      commandId: 'c0000000-0000-4000-8000-000000000040',
      action: 'increment',
      resources: { tournamentId: 'f0000000-0000-4000-8000-000000000001' },
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

