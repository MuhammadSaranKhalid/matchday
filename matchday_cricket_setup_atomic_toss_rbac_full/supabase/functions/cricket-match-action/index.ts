// =============================================================================
// cricket-match-action
// =============================================================================
//
// PURPOSE
// -------
// One authenticated command boundary for Cricket match workflow.
//
// IMPORTANT ARCHITECTURE RULE:
//
//   PostgreSQL = integrity
//   Edge       = behavior
//
// This function DOES NOT call one PL/pgSQL function per Cricket command.
// Instead it opens a real PostgreSQL transaction and the selected TypeScript
// command performs its reads, authorization checks and writes directly.
//
// Stable database infrastructure such as public.can(...), foreign keys,
// CHECK/UNIQUE constraints and RLS remains in PostgreSQL.
//
// TRANSACTION FLOW
// ----------------
//
//   authenticate request
//          ↓
//   parse action + match id
//          ↓
//   BEGIN
//          ↓
//   inject verified JWT claims
//          ↓
//   command handler
//     • lock authoritative rows
//     • authorize
//     • validate domain rules
//     • write state
//          ↓
//   read canonical snapshots
//          ↓
//   COMMIT
//          ↓
//   publish snapshots to Ably
//          ↓
//   HTTP response
//
// Realtime publishing is intentionally after COMMIT. Clients must never see a
// state transition that PostgreSQL later rolls back.
// =============================================================================

import "jsr:@supabase/functions-js/edge-runtime.d.ts";

import {
  corsPreflight,
  json,
} from "../_shared/http.ts";
import { db } from "../_shared/db.ts";
import {
  authenticateRequest,
  setTransactionJwtClaims,
} from "../record-ball/services/auth_service.ts";

import { dispatchCommand } from "./command_router.ts";
import { parseEnvelope } from "./domain/validation.ts";
import {
  normalizeUnexpectedError,
} from "./domain/errors.ts";
import { SnapshotRepository } from "./repositories/snapshot_repository.ts";
import { publishAfterCommit } from "./realtime/publisher.ts";
import type {
  TransactionOutput,
} from "./types.ts";

const snapshots = new SnapshotRepository();

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return corsPreflight();
  }

  // ---------------------------------------------------------------------------
  // 1. Authentication
  // ---------------------------------------------------------------------------
  // Never trust actor/user IDs from the JSON body.
  const auth = await authenticateRequest(req);

  if (auth.error || !auth.actorId) {
    return json(
      auth.error?.status ?? 401,
      {
        ok: false,
        error: {
          code:
            auth.error?.code ??
            "UNAUTHENTICATED",
          message:
            auth.error?.message ??
            "Invalid or missing session",
        },
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 2. Parse envelope
  // ---------------------------------------------------------------------------
  let raw: unknown;

  try {
    raw = await req.json();
  } catch {
    return json(400, {
      ok: false,
      error: {
        code: "BAD_REQUEST",
        message: "Invalid JSON body",
      },
    });
  }

  let envelope;

  try {
    envelope = parseEnvelope(raw);
  } catch (error) {
    const err =
      normalizeUnexpectedError(error);

    return json(err.status, {
      ok: false,
      error: {
        code: err.code,
        message: err.message,
      },
    });
  }

  const {
    action,
    matchId,
    body,
  } = envelope;

  const sql = db();

  try {
    // -------------------------------------------------------------------------
    // 3. ONE database transaction per command
    // -------------------------------------------------------------------------
    const out =
      await sql.begin<TransactionOutput>(
        async (tx) => {
          // public.can(...) and any policy/helper using auth.uid() see the
          // verified caller, even though this is a trusted direct DB connection.
          await setTransactionJwtClaims(
            tx,
            auth.actorId!,
          );

          // Business behavior lives here, in TypeScript command modules.
          const command =
            await dispatchCommand(
              action,
              {
                tx,
                actorId: auth.actorId!,
                matchId,
                body,
              },
            );

          // Snapshot is loaded INSIDE the transaction after all writes so the
          // response/realtime payload represents exactly what was committed.
          const match =
            await snapshots.match(
              tx,
              matchId,
            );

          const inningsNumber =
            command.inningsNumber ?? null;

          const innings =
            inningsNumber == null
              ? null
              : await snapshots.innings(
                  tx,
                  matchId,
                  inningsNumber,
                );

          return {
            result:
              command.result ?? null,
            match,
            innings,
            inningsNumber,
            ballsResync:
              command.ballsResync === true,
          };
        },
      );

    // -------------------------------------------------------------------------
    // 4. COMMIT has happened. Realtime is now safe to publish.
    // -------------------------------------------------------------------------
    await publishAfterCommit(
      matchId,
      action,
      out,
    );

    return json(200, {
      ok: true,
      result: out.result,
      match: out.match,
      innings: out.innings,
    });
  } catch (error) {
    const err =
      normalizeUnexpectedError(error);

    console.error(
      "[cricket-match-action]",
      action,
      {
        matchId,
        actorId: auth.actorId,
        code: err.code,
        message: err.message,
      },
    );

    return json(err.status, {
      ok: false,
      error: {
        code: err.code,
        message: err.message,
      },
    });
  }
});
