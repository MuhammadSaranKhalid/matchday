import { describe, expect, it, vi } from 'vitest';
import type { AuthenticatedPrincipal } from '@shared-kernel/identity/authenticated-principal.js';
import { TournamentCommandExecutor } from '../../../libs/modules/tournaments/src/application/command-executor/tournament-command-executor.js';
import { normalizeCommandResult } from '../../../libs/modules/tournaments/src/domain/command/json-result.js';
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


// ─── helpers ──────────────────────────────────────────────────────────────────

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

function makeFakeTxExecutor(): TournamentTransactionExecutor {
  return {
    withCommandTransaction: vi.fn(async (_principal, work) => work(mockQueryExecutor)),
  };
}

// ─── TournamentCommandExecutor — envelope validation ──────────────────────────

describe('TournamentCommandExecutor (unit)', () => {
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
    const fakeTxExecutor = makeFakeTxExecutor();
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
    const fakeTxExecutor = makeFakeTxExecutor();
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

  it('Requirement 6 & 20: executes handler and saves receipt on first invocation with valid UUID', async () => {
    const receiptRepo = createMockReceiptRepo();
    const fakeTxExecutor = makeFakeTxExecutor();
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
    const fakeTxExecutor = makeFakeTxExecutor();
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
    const fakeTxExecutor = makeFakeTxExecutor();
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
    const fakeTxExecutor = makeFakeTxExecutor();
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


// ─── normalizeCommandResult — extended result value space tests ────────────────

describe('normalizeCommandResult', () => {
  // ── Requirement 14: top-level undefined ──────────────────────────────────────
  it('Req 14: rejects top-level undefined', () => {
    expect(() => normalizeCommandResult(undefined)).toThrow(/undefined/i);
  });

  // ── Requirement 15: nested undefined in object ────────────────────────────────
  it('Req 15: rejects object with undefined property value', () => {
    expect(() => normalizeCommandResult({ a: 1, b: undefined })).toThrow(/undefined/i);
  });

  // ── Requirement 16: undefined in array ───────────────────────────────────────
  it('Req 16: rejects array containing undefined element', () => {
    expect(() => normalizeCommandResult([1, undefined, 3])).toThrow(/undefined/i);
  });

  // ── Requirement 17: Date object rejected; ISO string accepted ────────────────
  it('Req 17: rejects Date object', () => {
    expect(() => normalizeCommandResult({ createdAt: new Date() })).toThrow(/Date/i);
  });

  it('Req 17: accepts ISO-8601 string instead of Date', () => {
    const iso = new Date().toISOString();
    expect(() => normalizeCommandResult({ createdAt: iso })).not.toThrow();
    expect(normalizeCommandResult({ createdAt: iso })).toEqual({ createdAt: iso });
  });

  // ── Requirement 18: Map / Set / class instances ───────────────────────────────
  it('Req 18: rejects Map', () => {
    expect(() => normalizeCommandResult(new Map([['a', 1]]))).toThrow(/non-plain object/i);
  });

  it('Req 18: rejects Set', () => {
    expect(() => normalizeCommandResult(new Set([1, 2, 3]))).toThrow(/non-plain object/i);
  });

  it('Req 18: rejects class instance', () => {
    class Foo { x = 1; }
    expect(() => normalizeCommandResult(new Foo())).toThrow(/non-plain object/i);
  });

  it('Req 18: rejects RegExp', () => {
    expect(() => normalizeCommandResult(/pattern/u)).toThrow(/non-plain object/i);
  });

  it('Req 18: rejects BigInt', () => {
    expect(() => normalizeCommandResult(100n)).toThrow(/BigInt/i);
  });

  it('Req 18: rejects NaN', () => {
    expect(() => normalizeCommandResult(Number.NaN)).toThrow(/non-finite/i);
  });

  it('Req 18: rejects Infinity', () => {
    expect(() => normalizeCommandResult(Number.POSITIVE_INFINITY)).toThrow(/non-finite/i);
  });

  // ── Requirement 19: shared (non-circular) reference is allowed ───────────────
  it('Req 19: allows shared non-circular object references', () => {
    const child = { value: 1 };
    const result = { a: child, b: child };

    // Must NOT throw
    expect(() => normalizeCommandResult(result)).not.toThrow();

    // Must produce correct JSON-equivalent output
    const normalized = normalizeCommandResult(result);
    expect(normalized).toEqual({ a: { value: 1 }, b: { value: 1 } });
  });

  it('Req 19: allows shared non-circular array references', () => {
    const shared = [1, 2];
    const result = { x: shared, y: shared };
    expect(() => normalizeCommandResult(result)).not.toThrow();
    expect(normalizeCommandResult(result)).toEqual({ x: [1, 2], y: [1, 2] });
  });

  // ── Requirement 20: true circular reference is rejected ──────────────────────
  it('Req 20: rejects genuinely circular object', () => {
    const result: Record<string, unknown> = {};
    result['self'] = result;
    expect(() => normalizeCommandResult(result)).toThrow(/circular/i);
  });

  it('Req 20: rejects array that references itself', () => {
    const arr: unknown[] = [1];
    arr.push(arr);
    expect(() => normalizeCommandResult(arr)).toThrow(/circular/i);
  });

  // ── Allowed JSON primitives & plain structures ───────────────────────────────
  it('accepts null', () => {
    expect(normalizeCommandResult(null)).toBe(null);
  });

  it('accepts boolean', () => {
    expect(normalizeCommandResult(true)).toBe(true);
    expect(normalizeCommandResult(false)).toBe(false);
  });

  it('accepts finite numbers', () => {
    expect(normalizeCommandResult(0)).toBe(0);
    expect(normalizeCommandResult(42)).toBe(42);
    expect(normalizeCommandResult(-3.14)).toBe(-3.14);
  });

  it('accepts strings', () => {
    expect(normalizeCommandResult('hello')).toBe('hello');
    expect(normalizeCommandResult('')).toBe('');
  });

  it('accepts nested plain objects with sorted keys', () => {
    const result = normalizeCommandResult({ z: 2, a: 1, m: { y: 9, b: 8 } });
    // Keys must be sorted at each level
    expect(Object.keys(result as object)).toEqual(['a', 'm', 'z']);
    expect(Object.keys((result as Record<string, unknown>)['m'] as object)).toEqual(['b', 'y']);
  });

  it('accepts Object.create(null) plain object', () => {
    const bare = Object.create(null) as Record<string, unknown>;
    bare['x'] = 1;
    expect(normalizeCommandResult(bare)).toEqual({ x: 1 });
  });
});


// ─── Executor — result canonicalization roundtrip test (Req 21 & identity) ────

describe('TournamentCommandExecutor — canonical result identity invariant', () => {
  it('Req 21: first response.result and replay response.result are deeply equal', async () => {
    const receiptRepo = createMockReceiptRepo();
    const fakeTxExecutor = makeFakeTxExecutor();
    const executor = new TournamentCommandExecutor(fakeTxExecutor, receiptRepo);

    const complexResult = {
      id: 'f0000000-0000-4000-8000-000000000099',
      stats: { wins: 3, losses: 1, points: 9 },
      tags: ['champion', 'qualified'],
      active: true,
      score: null,
    };

    const cmd: TournamentCommand = {
      commandId: 'c0000000-0000-4000-8000-000000000050',
      action: 'compute_result',
      resources: {},
      payload: {},
    };

    const handler: TournamentCommandHandler<TournamentCommand, typeof complexResult> = {
      execute: vi.fn().mockResolvedValue(complexResult),
    };

    const first = await executor.execute(principalA, cmd, handler);
    expect(first.status).toBe('executed');

    const second = await executor.execute(principalA, cmd, handler);
    expect(second.status).toBe('replayed');

    // Core identity invariant
    expect(second.result).toEqual(first.result);
  });

  it('Req 22: serialization failure prevents receipt from being saved', async () => {
    const receiptRepo = createMockReceiptRepo();
    const fakeTxExecutor = makeFakeTxExecutor();
    const executor = new TournamentCommandExecutor(fakeTxExecutor, receiptRepo);

    const cmd: TournamentCommand = {
      commandId: 'c0000000-0000-4000-8000-000000000060',
      action: 'bad_result_action',
      resources: {},
      payload: {},
    };

    // Handler returns a BigInt — invalid
    const badHandler: TournamentCommandHandler<TournamentCommand, unknown> = {
      execute: vi.fn().mockResolvedValue({ count: 5n }),
    };

    await expect(executor.execute(principalA, cmd, badHandler)).rejects.toThrow(/BigInt/i);
    // Receipt must NOT have been saved
    expect(receiptRepo.saveReceipt).not.toHaveBeenCalled();
  });

  it('top-level undefined from handler is rejected (not silently coerced to null)', async () => {
    const receiptRepo = createMockReceiptRepo();
    const fakeTxExecutor = makeFakeTxExecutor();
    const executor = new TournamentCommandExecutor(fakeTxExecutor, receiptRepo);

    const cmd: TournamentCommand = {
      commandId: 'c0000000-0000-4000-8000-000000000070',
      action: 'void_action',
      resources: {},
      payload: {},
    };

    const voidHandler: TournamentCommandHandler<TournamentCommand, undefined> = {
      execute: vi.fn().mockResolvedValue(undefined),
    };

    await expect(executor.execute(principalA, cmd, voidHandler)).rejects.toThrow(/undefined/i);
    expect(receiptRepo.saveReceipt).not.toHaveBeenCalled();
  });

  it('Date object from handler is rejected (not silently stringified)', async () => {
    const receiptRepo = createMockReceiptRepo();
    const fakeTxExecutor = makeFakeTxExecutor();
    const executor = new TournamentCommandExecutor(fakeTxExecutor, receiptRepo);

    const cmd: TournamentCommand = {
      commandId: 'c0000000-0000-4000-8000-000000000080',
      action: 'date_action',
      resources: {},
      payload: {},
    };

    const dateHandler: TournamentCommandHandler<TournamentCommand, unknown> = {
      execute: vi.fn().mockResolvedValue({ createdAt: new Date() }),
    };

    await expect(executor.execute(principalA, cmd, dateHandler)).rejects.toThrow(/Date/i);
    expect(receiptRepo.saveReceipt).not.toHaveBeenCalled();
  });

  it('shared non-circular reference in handler result is accepted', async () => {
    const receiptRepo = createMockReceiptRepo();
    const fakeTxExecutor = makeFakeTxExecutor();
    const executor = new TournamentCommandExecutor(fakeTxExecutor, receiptRepo);

    const cmd: TournamentCommand = {
      commandId: 'c0000000-0000-4000-8000-000000000090',
      action: 'shared_ref_action',
      resources: {},
      payload: {},
    };

    const child = { value: 1 };
    const sharedRefHandler: TournamentCommandHandler<TournamentCommand, unknown> = {
      execute: vi.fn().mockResolvedValue({ a: child, b: child }),
    };

    const result = await executor.execute(principalA, cmd, sharedRefHandler);
    expect(result.status).toBe('executed');
    expect(result.result).toEqual({ a: { value: 1 }, b: { value: 1 } });
  });
});
