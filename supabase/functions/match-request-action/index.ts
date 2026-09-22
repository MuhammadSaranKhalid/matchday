// =============================================================================
// match-request-action
// =============================================================================
//
// PURPOSE
// -------
// One authenticated command boundary for match request acceptance.
//
// ARCHITECTURE:
//   PostgreSQL = integrity and authoritative state
//   Edge       = behavior, authorization sequencing, and command orchestration
//
// TRANSACTION FLOW
// ----------------
//   authenticate request
//          ↓
//   parse action envelope
//          ↓
//   BEGIN
//          ↓
//   inject verified JWT claims → setTransactionJwtClaims
//          ↓
//   route to command:
//     • lock challenge/application rows FOR UPDATE
//     • authorize actor via is_team_manager()
//     • validate rosters and captains
//     • create normalized match aggregate
//     • guarded terminal transition (zero rows → CONFLICT → rollback)
//          ↓
//   COMMIT
//          ↓
//   HTTP response: { ok: true, match_id }
//
// NO match-runtime Ably event is emitted: acceptance creates a new match that
// no client is yet subscribed to. Notification triggers fire transactionally
// via existing database trigger infrastructure.
// =============================================================================

import "jsr:@supabase/functions-js/edge-runtime.d.ts";

import { corsPreflight, json } from "../_shared/http.ts";
import { db } from "../_shared/db.ts";
import {
  authenticateRequest,
  setTransactionJwtClaims,
} from "../record-ball/services/auth_service.ts";
import type { AuthResult } from "../record-ball/services/auth_service.ts";

import { parseEnvelope } from "./domain/validation.ts";
import { normalizeUnexpectedError } from "./domain/errors.ts";
import { routeCommand } from "./command_router.ts";
import type { Action } from "./types.ts";

// ---------------------------------------------------------------------------
// Dependency interface (injected in tests, real in production)
// ---------------------------------------------------------------------------

export interface HandlerDependencies {
  authenticate(req: Request): Promise<AuthResult>;
  runCommand(
    action: Action,
    actorId: string,
    body: Record<string, unknown>,
  ): Promise<{ matchId: string }>;
}

// ---------------------------------------------------------------------------
// Testable handler — separated from Deno.serve so tests can inject fakes
// ---------------------------------------------------------------------------

export async function handleRequest(
  req: Request,
  deps: HandlerDependencies,
): Promise<Response> {
  // ── CORS preflight ───────────────────────────────────────────────────────
  if (req.method === "OPTIONS") {
    return corsPreflight();
  }

  // ── 1. Authentication ────────────────────────────────────────────────────
  // Never trust actor/user IDs from the JSON body.
  const auth = await deps.authenticate(req);

  if (auth.error || !auth.actorId) {
    return json(auth.error?.status ?? 401, {
      ok: false,
      error: {
        code: auth.error?.code ?? "UNAUTHENTICATED",
        message: auth.error?.message ?? "Invalid or missing session",
      },
    });
  }

  // ── 2. Parse envelope ────────────────────────────────────────────────────
  let raw: unknown;
  try {
    raw = await req.json();
  } catch {
    return json(400, {
      ok: false,
      error: { code: "BAD_REQUEST", message: "Invalid JSON body" },
    });
  }

  let action: Action;
  let body: Record<string, unknown>;

  try {
    const envelope = parseEnvelope(raw);
    action = envelope.action;
    body = envelope.body;
  } catch (error) {
    const err = normalizeUnexpectedError(error);
    return json(err.status, {
      ok: false,
      error: { code: err.code, message: err.message },
    });
  }

  // ── 3. Execute command ───────────────────────────────────────────────────
  try {
    const result = await deps.runCommand(action, auth.actorId!, body);

    // Guard: a successful command that returns an empty matchId is a server
    // failure — Flutter must not navigate with invalid state.
    if (!result.matchId) {
      console.error("[match-request-action] runCommand returned empty matchId", {
        action,
        actorId: auth.actorId,
      });
      return json(500, {
        ok: false,
        error: { code: "INTERNAL_ERROR", message: "Server error: match creation returned no ID" },
      });
    }

    return json(200, { ok: true, match_id: result.matchId });
  } catch (error) {
    const err = normalizeUnexpectedError(error);

    // Log action, actor, and error code — never log tokens or full body.
    console.error("[match-request-action]", action, {
      actorId: auth.actorId,
      code: err.code,
      message: err.message,
    });

    return json(err.status, {
      ok: false,
      error: { code: err.code, message: err.message },
    });
  }
}

// ---------------------------------------------------------------------------
// Production dependencies
// ---------------------------------------------------------------------------

const productionDeps: HandlerDependencies = {
  authenticate: (req) => authenticateRequest(req),
  async runCommand(action, actorId, body) {
    // Lazy: db() reads SUPABASE_URL env var; don't call at import time so
    // that unit tests (which don't need a DB) can import without permissions.
    const sql = db();
    return await sql.begin(async (tx) => {
      // Install verified identity into transaction-local JWT claims so
      // is_team_manager(), _validate_team_xi(), and notification triggers
      // all see the real auth.uid().
      await setTransactionJwtClaims(tx, actorId);
      return await routeCommand(tx, action, actorId, body);
    });
  },
};

// ---------------------------------------------------------------------------
// HTTP server entry point
// ---------------------------------------------------------------------------

if (import.meta.main) {
  Deno.serve((req) => handleRequest(req, productionDeps));
}
