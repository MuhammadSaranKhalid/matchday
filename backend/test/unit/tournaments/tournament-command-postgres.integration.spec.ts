import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import type { AuthenticatedPrincipal } from '@shared-kernel/identity/authenticated-principal.js';
import type { DatabaseConfiguration } from '../../../libs/platform/src/config/configuration.js';
import { DatabaseExecutorService } from '../../../libs/platform/src/database/database-executor.service.js';
import { PostgresPoolService } from '../../../libs/platform/src/database/postgres-pool.service.js';
import { TournamentCommandExecutor } from '../../../libs/modules/tournaments/src/application/command-executor/tournament-command-executor.js';
import type {
  TournamentCommandHandler,
  TournamentTransactionExecutor,
} from '../../../libs/modules/tournaments/src/application/ports/tournament-command.ports.js';
import type { TournamentCommand } from '../../../libs/modules/tournaments/src/domain/command/tournament-command.js';
import {
  TOURNAMENT_ERROR_CODES,
  TournamentError,
} from '../../../libs/modules/tournaments/src/domain/errors/tournament-error-codes.js';
import { PostgresTournamentAuthorizationRepository } from '../../../libs/modules/tournaments/src/infrastructure/persistence/postgres-tournament-authorization.repository.js';
import { PostgresTournamentCommandReceiptRepository } from '../../../libs/modules/tournaments/src/infrastructure/persistence/postgres-tournament-command-receipt.repository.js';
import { PostgresTournamentRootRepository } from '../../../libs/modules/tournaments/src/infrastructure/persistence/postgres-tournament-root.repository.js';

const databaseUrl =
  process.env.DATABASE_URL ??
  'postgresql://postgres:postgres@127.0.0.1:55322/postgres';

const configuration: DatabaseConfiguration = {
  url: databaseUrl,
  poolMax: 10,
  connectionTimeoutMs: 5_000,
  idleTimeoutMs: 10_000,
  statementTimeoutMs: 5_000,
  sslMode: 'disable',
};

const pool = new PostgresPoolService(configuration);
const dbService = new DatabaseExecutorService(pool);

const txExecutor: TournamentTransactionExecutor = {
  withCommandTransaction: (principal, work) =>
    dbService.withCommandTransaction(principal, (client) => work(client)),
};

const receiptRepo = new PostgresTournamentCommandReceiptRepository();
const authRepo = new PostgresTournamentAuthorizationRepository();
const rootRepo = new PostgresTournamentRootRepository();
const executor = new TournamentCommandExecutor(txExecutor, receiptRepo);

describe('Tournament Command Infrastructure PostgreSQL Integration', () => {
  const userA: AuthenticatedPrincipal = {
    userId: '00000000-0000-0000-0000-000000000001',
    sessionId: '50000000-0000-4000-8000-000000000001',
    appMetadata: { tier: 'pro' },
  };

  const userB: AuthenticatedPrincipal = {
    userId: '00000000-0000-0000-0000-000000000002',
    sessionId: '50000000-0000-4000-8000-000000000002',
    appMetadata: {},
  };

  let testTournamentId: string;

  beforeAll(async () => {
    // 1. Create test probe table for synthetic handler testing
    await pool.query(`
      CREATE TABLE IF NOT EXISTS public.test_tournament_command_probe (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        command_id text NOT NULL,
        counter integer NOT NULL DEFAULT 1,
        created_at timestamptz NOT NULL DEFAULT now()
      )
    `);

    // 2. Create a canonical test tournament owned by userA
    testTournamentId = 'f0000000-0000-4000-8000-000000000001';
    await pool.query(
      `INSERT INTO public.tournaments (
        tournament_id,
        tournament_name,
        tournament_type,
        sport_id,
        owner_user_id,
        publication_state,
        registration_state,
        entry_state,
        competition_state,
        termination_state,
        revision,
        entry_revision
      ) VALUES ($1, 'Command Test Cup', 'knockout', 'cricket', $2, 'draft', 'not_open', 'editable', 'not_started', 'none', 4, 1)
      ON CONFLICT (tournament_id) DO UPDATE
      SET owner_user_id = EXCLUDED.owner_user_id,
          publication_state = 'draft',
          revision = 4,
          entry_revision = 1`,
      [testTournamentId, userA.userId],
    );
  });

  afterAll(async () => {
    try {
      await pool.query(`DROP TABLE IF EXISTS public.test_tournament_command_probe`);
      await pool.query(`DELETE FROM private.tournament_command_receipts WHERE tournament_id = $1`, [testTournamentId]);
      await pool.query(`DELETE FROM public.tournaments WHERE tournament_id = $1`, [testTournamentId]);
    } finally {
      await pool.onApplicationShutdown();
    }
  });

  it('Requirement 13: withCommandTransaction sets auth.uid() and evaluates public.can(...)', async () => {
    await dbService.withCommandTransaction(userA, async (tx) => {
      const uidResult = await tx.query<{ uid: string }>('select auth.uid() as uid');
      expect(uidResult.rows[0]?.uid).toBe(userA.userId);

      // Verify public.can resolves registered permissions for auth.uid()
      const canStructure = await authRepo.can(tx, testTournamentId, 'tournament.structure.manage');
      expect(canStructure).toBe(true);

      const canPublish = await authRepo.can(tx, testTournamentId, 'tournament.publish');
      expect(canPublish).toBe(true);
    });

    await dbService.withCommandTransaction(userB, async (tx) => {
      const uidResult = await tx.query<{ uid: string }>('select auth.uid() as uid');
      expect(uidResult.rows[0]?.uid).toBe(userB.userId);

      // User B is not owner/manager, so canStructure should be false
      const canStructure = await authRepo.can(tx, testTournamentId, 'tournament.structure.manage');
      expect(canStructure).toBe(false);
    });
  });

  it('Requirement 52: withSystemTransaction remains actorless', async () => {
    await dbService.withSystemTransaction(async (tx) => {
      const uidResult = await tx.query<{ uid: string | null }>('select auth.uid() as uid');
      expect(uidResult.rows[0]?.uid).toBeNull();

      const claimsResult = await tx.query<{ claims: string | null }>(
        "select current_setting('request.jwt.claims', true) as claims",
      );
      expect(claimsResult.rows[0]?.claims ?? '').toBe('');
    });
  });

  it('Requirement 14 & 51: withCommandTransaction enables server structural writes while direct withUserTransaction is denied by RLS', async () => {
    const stageId = 'e0000000-0000-4000-8000-000000000001';

    // 1. Direct Data API / user transaction (SET ROLE authenticated) -> DENIED
    await expect(
      dbService.withUserTransaction(userA, async (tx) => {
        await tx.query(
          `INSERT INTO public.tournament_stages (
            stage_id, tournament_id, sequence, name, competition_format
          ) VALUES ($1, $2, 1, 'Group Stage', 'round_robin')`,
          [stageId, testTournamentId],
        );
      }),
    ).rejects.toThrow(); // RLS violation

    // Verify row was NOT inserted
    const checkUser = await pool.query(
      `SELECT count(*)::int as count FROM public.tournament_stages WHERE stage_id = $1`,
      [stageId],
    );
    expect(checkUser.rows[0]?.count).toBe(0);

    // 2. withCommandTransaction (trusted database role + injected JWT claims) -> ALLOWED
    await dbService.withCommandTransaction(userA, async (tx) => {
      await tx.query(
        `INSERT INTO public.tournament_stages (
          stage_id, tournament_id, sequence, name, competition_format
        ) VALUES ($1, $2, 1, 'Group Stage', 'round_robin')`,
        [stageId, testTournamentId],
      );
    });

    // Verify row was inserted successfully
    const checkCommand = await pool.query(
      `SELECT count(*)::int as count FROM public.tournament_stages WHERE stage_id = $1`,
      [stageId],
    );
    expect(checkCommand.rows[0]?.count).toBe(1);

    // Clean up inserted stage
    await pool.query(`DELETE FROM public.tournament_stages WHERE stage_id = $1`, [stageId]);
  });

  it('Requirements 11 & 12: database role verification and transaction mode separation', async () => {
    // 1. withCommandTransaction retains trusted backend DB role and does NOT set role authenticated
    await dbService.withCommandTransaction(userA, async (tx) => {
      const roleResult = await tx.query<{
        current_user: string;
        session_user: string;
      }>('SELECT current_user, session_user');
      expect(roleResult.rows[0]?.current_user).not.toBe('authenticated');
      expect(roleResult.rows[0]?.current_user).toBe('postgres');
      expect(roleResult.rows[0]?.session_user).toBe('postgres');

      const privResult = await tx.query<{
        rolname: string;
        rolbypassrls: boolean;
        rolsuper: boolean;
      }>(
        `SELECT rolname, rolbypassrls, rolsuper FROM pg_roles WHERE rolname = current_user`,
      );
      expect(privResult.rows[0]?.rolname).toBe('postgres');
      expect(privResult.rows[0]?.rolbypassrls).toBe(true);
      expect(privResult.rows[0]?.rolsuper).toBe(false);

      // Verify JWT claims set transaction-locally
      const uidResult = await tx.query<{ uid: string }>('SELECT auth.uid() as uid');
      expect(uidResult.rows[0]?.uid).toBe(userA.userId);
    });

    // 2. withUserTransaction switches role to authenticated
    await dbService.withUserTransaction(userA, async (tx) => {
      const roleResult = await tx.query<{ current_user: string }>('SELECT current_user');
      expect(roleResult.rows[0]?.current_user).toBe('authenticated');
    });

    // 3. withSystemTransaction retains trusted backend role without actor
    await dbService.withSystemTransaction(async (tx) => {
      const roleResult = await tx.query<{ current_user: string }>('SELECT current_user');
      expect(roleResult.rows[0]?.current_user).toBe('postgres');
      const uidResult = await tx.query<{ uid: string | null }>('SELECT auth.uid() as uid');
      expect(uidResult.rows[0]?.uid).toBeNull();
    });
  });

  it('Requirement 21: normal client roles cannot SELECT, INSERT, UPDATE, or DELETE from private.tournament_command_receipts', async () => {
    const dummyReceiptId = 'd0000000-0000-4000-8000-000000000001';

    // 1. SELECT as authenticated -> DENIED
    await expect(
      dbService.withUserTransaction(userA, async (tx) => {
        await tx.query('SELECT * FROM private.tournament_command_receipts LIMIT 1');
      }),
    ).rejects.toThrow(/permission denied/i);

    // 2. INSERT as authenticated -> DENIED
    await expect(
      dbService.withUserTransaction(userA, async (tx) => {
        await tx.query(
          `INSERT INTO private.tournament_command_receipts (
            command_id, actor_id, action, request_fingerprint
          ) VALUES ($1, $2, 'test', 'hash')`,
          [dummyReceiptId, userA.userId],
        );
      }),
    ).rejects.toThrow(/permission denied/i);

    // 3. UPDATE as authenticated -> DENIED
    await expect(
      dbService.withUserTransaction(userA, async (tx) => {
        await tx.query(
          `UPDATE private.tournament_command_receipts SET action = 'tampered' WHERE command_id = $1`,
          [dummyReceiptId],
        );
      }),
    ).rejects.toThrow(/permission denied/i);

    // 4. DELETE as authenticated -> DENIED
    await expect(
      dbService.withUserTransaction(userA, async (tx) => {
        await tx.query(
          `DELETE FROM private.tournament_command_receipts WHERE command_id = $1`,
          [dummyReceiptId],
        );
      }),
    ).rejects.toThrow(/permission denied/i);

    // 5. Trusted withCommandTransaction CAN manage receipts
    await dbService.withCommandTransaction(userA, async (tx) => {
      await tx.query(
        `INSERT INTO private.tournament_command_receipts (
          command_id, actor_id, action, request_fingerprint
        ) VALUES ($1, $2, 'trusted_test', 'hash')`,
        [dummyReceiptId, userA.userId],
      );
      const inserted = await tx.query<{ action: string }>(
        `SELECT action FROM private.tournament_command_receipts WHERE command_id = $1`,
        [dummyReceiptId],
      );
      expect(inserted.rows[0]?.action).toBe('trusted_test');

      await tx.query(
        `DELETE FROM private.tournament_command_receipts WHERE command_id = $1`,
        [dummyReceiptId],
      );
    });
  });

  it('Requirement 43: rolls back mutation and saves no receipt on failure', async () => {
    const commandId = 'c0000000-0000-4000-8000-000000000001';
    const failingCommand: TournamentCommand<{ value: string }> = {
      commandId,
      action: 'failing_action',
      resources: { tournamentId: testTournamentId },
      payload: { value: 'probe-data' },
    };

    const failingHandler: TournamentCommandHandler<typeof failingCommand, void> = {
      execute: async (ctx, cmd) => {
        await ctx.tx.query(
          `INSERT INTO public.test_tournament_command_probe (command_id, counter) VALUES ($1, 999)`,
          [cmd.commandId],
        );
        throw TournamentError.badRequest('Deliberate test failure for rollback verification');
      },
    };

    await expect(executor.execute(userA, failingCommand, failingHandler)).rejects.toThrow(
      TournamentError,
    );

    // Assert mutation is absent
    const probeResult = await pool.query(
      `SELECT count(*)::int as count FROM public.test_tournament_command_probe WHERE command_id = $1`,
      [commandId],
    );
    expect(probeResult.rows[0]?.count).toBe(0);

    // Assert receipt is absent
    const receipt = await receiptRepo.findReceipt(pool as never, commandId);
    expect(receipt).toBeNull();
  });

  it('Requirement 44: successful idempotency executes once and replays persisted response', async () => {
    const commandId = 'c0000000-0000-4000-8000-000000000002';
    const command: TournamentCommand<{ name: string }> = {
      commandId,
      action: 'increment_counter',
      resources: { tournamentId: testTournamentId },
      payload: { name: 'first-run' },
    };

    let handlerCalls = 0;
    const handler: TournamentCommandHandler<typeof command, { counterValue: number }> = {
      execute: async (ctx, cmd) => {
        handlerCalls += 1;
        await ctx.tx.query(
          `INSERT INTO public.test_tournament_command_probe (command_id, counter) VALUES ($1, $2)`,
          [cmd.commandId, 1],
        );
        return { counterValue: 1 };
      },
    };

    // First call
    const res1 = await executor.execute(userA, command, handler);
    expect(res1.status).toBe('executed');
    expect(res1.result).toEqual({ counterValue: 1 });
    expect(handlerCalls).toBe(1);

    // Verify row and receipt in DB
    const probe1 = await pool.query<{ counter: number }>(
      `SELECT counter FROM public.test_tournament_command_probe WHERE command_id = $1`,
      [commandId],
    );
    expect(probe1.rows).toHaveLength(1);
    expect(probe1.rows[0]?.counter).toBe(1);

    const receipt = await receiptRepo.findReceipt(pool as never, commandId);
    expect(receipt).not.toBeNull();
    expect(receipt?.actorId).toBe(userA.userId);
    expect(receipt?.action).toBe('increment_counter');

    // Second call with same commandId
    const res2 = await executor.execute(userA, command, handler);
    expect(res2.status).toBe('replayed');
    expect(res2.result).toEqual({ counterValue: 1 });
    expect(handlerCalls).toBe(1); // Handler was NOT executed again!

    // Verify still exactly 1 probe row in DB
    const probe2 = await pool.query(
      `SELECT count(*)::int as count FROM public.test_tournament_command_probe WHERE command_id = $1`,
      [commandId],
    );
    expect(probe2.rows[0]?.count).toBe(1);
  });

  it('Requirement 45: concurrent duplicate commands execute once and both receive success', async () => {
    const commandId = 'c0000000-0000-4000-8000-000000000003';
    const command: TournamentCommand<{ flag: boolean }> = {
      commandId,
      action: 'concurrent_action',
      resources: { tournamentId: testTournamentId },
      payload: { flag: true },
    };

    let handlerExecutions = 0;
    const handler: TournamentCommandHandler<typeof command, { executedAt: string }> = {
      execute: async (ctx, cmd) => {
        handlerExecutions += 1;
        // Small delay to simulate work under concurrency
        await ctx.tx.query('SELECT pg_sleep(0.05)');
        await ctx.tx.query(
          `INSERT INTO public.test_tournament_command_probe (command_id, counter) VALUES ($1, $2)`,
          [cmd.commandId, 42],
        );
        return { executedAt: new Date().toISOString() };
      },
    };

    // Execute two concurrent requests simultaneously
    const [resultA, resultB] = await Promise.all([
      executor.execute(userA, command, handler),
      executor.execute(userA, command, handler),
    ]);

    expect(handlerExecutions).toBe(1);
    expect(resultA.result).toEqual(resultB.result);

    const statuses = [resultA.status, resultB.status].sort();
    expect(statuses).toEqual(['executed', 'replayed']);

    // Assert exactly 1 mutation row in DB
    const probeRows = await pool.query(
      `SELECT count(*)::int as count FROM public.test_tournament_command_probe WHERE command_id = $1`,
      [commandId],
    );
    expect(probeRows.rows[0]?.count).toBe(1);

    // Assert exactly 1 receipt in DB
    const receiptRows = await pool.query(
      `SELECT count(*)::int as count FROM private.tournament_command_receipts WHERE command_id = $1`,
      [commandId],
    );
    expect(receiptRows.rows[0]?.count).toBe(1);
  });

  it('Requirement 46: actor isolation produces IDEMPOTENCY_CONFLICT when User B tries User A commandId', async () => {
    const commandId = 'c0000000-0000-4000-8000-000000000004';
    const command: TournamentCommand = {
      commandId,
      action: 'isolated_action',
      resources: { tournamentId: testTournamentId },
      payload: { secret: 'data' },
    };

    const handler: TournamentCommandHandler<TournamentCommand, { done: boolean }> = {
      execute: async () => ({ done: true }),
    };

    // User A executes successfully
    const resA = await executor.execute(userA, command, handler);
    expect(resA.status).toBe('executed');

    // User B tries to submit with same commandId -> IDEMPOTENCY_CONFLICT (no response leak)
    await expect(executor.execute(userB, command, handler)).rejects.toThrow(
      expect.objectContaining({
        code: TOURNAMENT_ERROR_CODES.IDEMPOTENCY_CONFLICT,
      }),
    );
  });

  it('Requirement 22: different action, payload, or resources with same commandId produces IDEMPOTENCY_CONFLICT', async () => {
    const commandId = 'c0000000-0000-4000-8000-000000000009';
    const baseCommand: TournamentCommand<{ val: string }> = {
      commandId,
      action: 'semantic_action',
      resources: { tournamentId: testTournamentId },
      payload: { val: 'original' },
    };

    const handler: TournamentCommandHandler<typeof baseCommand, { ok: boolean }> = {
      execute: async () => ({ ok: true }),
    };

    const res = await executor.execute(userA, baseCommand, handler);
    expect(res.status).toBe('executed');

    // 1. Same actor, same commandId, different action -> CONFLICT
    await expect(
      executor.execute(
        userA,
        { ...baseCommand, action: 'different_action' },
        handler,
      ),
    ).rejects.toThrow(
      expect.objectContaining({
        code: TOURNAMENT_ERROR_CODES.IDEMPOTENCY_CONFLICT,
      }),
    );

    // 2. Same actor, same commandId, different payload -> CONFLICT
    await expect(
      executor.execute(
        userA,
        { ...baseCommand, payload: { val: 'mutated' } },
        handler,
      ),
    ).rejects.toThrow(
      expect.objectContaining({
        code: TOURNAMENT_ERROR_CODES.IDEMPOTENCY_CONFLICT,
      }),
    );

    // 3. Same actor, same commandId, different resource -> CONFLICT
    await expect(
      executor.execute(
        userA,
        {
          ...baseCommand,
          resources: { tournamentId: 'f0000000-0000-4000-8000-000000000099' },
        },
        handler,
      ),
    ).rejects.toThrow(
      expect.objectContaining({
        code: TOURNAMENT_ERROR_CODES.IDEMPOTENCY_CONFLICT,
      }),
    );
  });

  it('Requirement 48: expected revision replay vs stale revision conflict', async () => {
    const commandId = 'c0000000-0000-4000-8000-000000000005';
    const command: TournamentCommand = {
      commandId,
      action: 'bump_revision',
      resources: { tournamentId: testTournamentId },
      expectedRevision: 4, // Tournament is currently at revision 4
      payload: {},
    };

    const handler: TournamentCommandHandler<TournamentCommand, { bumped: boolean; newRev: number }> = {
      execute: async (ctx) => {
        // Authoritative lock & read
        const root = await rootRepo.lockTournament(ctx.tx, testTournamentId);
        expect(root.revision).toBe(4);

        // Bump revision to 5
        await ctx.tx.query(
          `UPDATE public.tournaments SET revision = 5 WHERE tournament_id = $1`,
          [testTournamentId],
        );
        return { bumped: true, newRev: 5 };
      },
    };

    // First call: succeeds and bumps revision to 5
    const res1 = await executor.execute(userA, command, handler);
    expect(res1.status).toBe('executed');
    expect(res1.result).toEqual({ bumped: true, newRev: 5 });

    // Verify tournament revision in DB is now 5
    const checkRev = await rootRepo.findTournament(pool as never, testTournamentId);
    expect(checkRev?.revision).toBe(5);

    // Retry with SAME commandId and expectedRevision 4:
    // Must replay original success without STALE_REVISION error!
    const res2 = await executor.execute(userA, command, handler);
    expect(res2.status).toBe('replayed');
    expect(res2.result).toEqual({ bumped: true, newRev: 5 });

    // Now send a NEW commandId with stale expectedRevision 4
    const newStaleCommand: TournamentCommand = {
      commandId: 'c0000000-0000-4000-8000-000000000006',
      action: 'another_action',
      resources: { tournamentId: testTournamentId },
      expectedRevision: 4, // Stale! Revision is already 5
      payload: {},
    };

    const staleHandler: TournamentCommandHandler<TournamentCommand, void> = {
      execute: async (ctx, cmd) => {
        const root = await rootRepo.lockTournament(ctx.tx, testTournamentId);
        if (cmd.expectedRevision !== undefined && cmd.expectedRevision !== root.revision) {
          throw TournamentError.staleRevision(cmd.expectedRevision, root.revision);
        }
      },
    };

    await expect(executor.execute(userA, newStaleCommand, staleHandler)).rejects.toThrow(
      expect.objectContaining({
        code: TOURNAMENT_ERROR_CODES.STALE_REVISION,
      }),
    );
  });

  it('Requirement 36: TournamentRootRepository lockTournament locks row with FOR UPDATE', async () => {
    await dbService.withCommandTransaction(userA, async (tx) => {
      const root = await rootRepo.lockTournament(tx, testTournamentId);
      expect(root.tournamentId).toBe(testTournamentId);
      expect(root.sportId).toBe('cricket');
      expect(root.ownerUserId).toBe(userA.userId);
      expect(root.publicationState).toBe('draft');
      expect(root.registrationState).toBe('not_open');
      expect(root.entryState).toBe('editable');
      expect(root.competitionState).toBe('not_started');
      expect(root.terminationState).toBe('none');
      expect(root.revision).toBeGreaterThanOrEqual(1);
      expect(root.entryRevision).toBeGreaterThanOrEqual(1);
    });
  });

  it('Requirement 35: TournamentAuthorizationRepository require() throws forbidden on missing capability', async () => {
    await dbService.withCommandTransaction(userB, async (tx) => {
      await expect(
        authRepo.require(tx, testTournamentId, 'tournament.structure.manage'),
      ).rejects.toThrow(
        expect.objectContaining({
          code: TOURNAMENT_ERROR_CODES.FORBIDDEN,
        }),
      );
    });
  });

  it('Requirement 6 (serialization rollback): normalizeCommandResult failure after handler execution rolls back probe row and saves no receipt', async () => {
    // This test proves that if normalizeCommandResult throws AFTER the handler
    // has executed side-effects (e.g., writing a probe row within the same
    // transaction) but BEFORE the receipt is persisted, the entire transaction
    // is rolled back atomically. This is distinct from Req 43 (handler throws)
    // which tests failure during handler execution itself.
    const commandId = 'c0000000-0000-4000-8000-000000000007';
    const command: TournamentCommand<{ label: string }> = {
      commandId,
      action: 'serialize_fail_action',
      resources: { tournamentId: testTournamentId },
      payload: { label: 'serialization-rollback-probe' },
    };

    // Handler writes a probe row successfully, then returns a BigInt value
    // which normalizeCommandResult will refuse to serialize.
    const handlerWithBadResult: TournamentCommandHandler<typeof command, unknown> = {
      execute: async (ctx, cmd) => {
        // Side-effect: write probe row (this succeeds inside the transaction)
        await ctx.tx.query(
          `INSERT INTO public.test_tournament_command_probe (command_id, counter) VALUES ($1, 777)`,
          [cmd.commandId],
        );
        // Return a non-serializable value to trigger normalizeCommandResult failure
        // after the handler has completed but before the receipt is persisted.
        return { invalidValue: BigInt(42) };
      },
    };

    // The executor must throw (BigInt is not JSON-serializable)
    await expect(executor.execute(userA, command, handlerWithBadResult)).rejects.toThrow(
      /BigInt/i,
    );

    // Assert: probe row must be ABSENT — the entire transaction was rolled back
    const probeResult = await pool.query(
      `SELECT count(*)::int as count FROM public.test_tournament_command_probe WHERE command_id = $1`,
      [commandId],
    );
    expect(probeResult.rows[0]?.count).toBe(0);

    // Assert: receipt must be ABSENT — no receipt was persisted
    const receipt = await receiptRepo.findReceipt(pool as never, commandId);
    expect(receipt).toBeNull();
  });
});
