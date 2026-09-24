// send-match-request — edge orchestrator for the Match Challenge send flow.
//
// Flow:
//   1. identify the caller (JWT → actor)
//   2. parse + shallow-validate the body
//   3. format validation (via validateChallengeFormat)
//   4. authorise: caller must manage `p_from_team_id`
//   5. one Postgres transaction:
//        block duplicates for targeted requests →
//        mint a unique 6-digit share code (retry up to 6 times) →
//        insert the row with a 24h code expiry + 48h proposal expiry →
//        commit
//   6. return { ok: true, request_id, share_code, ... }

import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { db, userClient } from "../_shared/db.ts";
import { json } from "../_shared/http.ts";
import {
  validateChallengeFormat,
  type ValidatedCricketFormat,
} from "../match-request-action/domain/format_validation.ts";

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function reply(status: number, body: unknown): Response {
  const res = json(status, body);
  for (const [k, v] of Object.entries(CORS)) {
    res.headers.set(k, v);
  }
  return res;
}

/** Thrown inside the transaction to roll back with a specific HTTP status. */
class HttpSignal {
  constructor(
    readonly status: number,
    readonly code: string,
    readonly message: string,
  ) {}
}

const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

function mintCode(): string {
  // 6-digit zero-padded numeric code.
  return Math.floor(Math.random() * 1_000_000).toString().padStart(6, "0");
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  if (req.method !== "POST") {
    return reply(405, {
      ok: false,
      error: { code: "method_not_allowed", message: "POST only" },
    });
  }

  // 1. Authn.
  const authHeader = req.headers.get("Authorization") ?? "";
  if (!authHeader.startsWith("Bearer ")) {
    return reply(401, {
      ok: false,
      error: { code: "unauthenticated", message: "Missing bearer token" },
    });
  }
  const asUser = userClient(authHeader);
  const { data: userData, error: userErr } = await asUser.auth.getUser();
  const actor = userData?.user?.id;
  if (userErr || !actor) {
    return reply(401, {
      ok: false,
      error: { code: "unauthenticated", message: "Invalid session" },
    });
  }

  // 2. Parse.
  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return reply(400, {
      ok: false,
      error: { code: "bad_json", message: "Body is not JSON" },
    });
  }

  const fromTeamId = body.p_from_team_id as string | undefined;
  const toTeamId = (body.p_to_team_id as string | null | undefined) ?? null;
  const proposedStartTime =
    (body.p_proposed_start_time as string | null | undefined) ?? null;
  const proposedVenue =
    (body.p_proposed_venue as string | null | undefined) ?? null;
  const proposedFormatInput =
    (body.p_proposed_format as Record<string, unknown> | null | undefined) ??
    {};
  const proposedFormatCode =
    (body.p_proposed_format_code as string | undefined) ??
    (body.p_format_code as string | undefined) ??
    (proposedFormatInput.format_code as string | undefined) ??
    "t20";
  const message = (body.p_message as string | null | undefined) ?? null;

  // Shallow shape checks
  if (!fromTeamId || !UUID_RE.test(fromTeamId)) {
    return reply(400, {
      ok: false,
      error: {
        code: "bad_request",
        message: "p_from_team_id must be a uuid",
      },
    });
  }
  if (toTeamId !== null && (!UUID_RE.test(toTeamId))) {
    return reply(400, {
      ok: false,
      error: {
        code: "bad_request",
        message: "p_to_team_id must be a uuid or null",
      },
    });
  }
  if (toTeamId !== null && toTeamId === fromTeamId) {
    return reply(422, {
      ok: false,
      error: {
        code: "self_challenge",
        message: "A team cannot challenge itself",
      },
    });
  }

  // 3. Format validation
  let validatedFormat: ValidatedCricketFormat;
  try {
    validatedFormat = validateChallengeFormat(
      proposedFormatCode,
      proposedFormatInput,
    );
  } catch (err: unknown) {
    // deno-lint-ignore no-explicit-any
    const status = (err as any)?.status ?? 422;
    // deno-lint-ignore no-explicit-any
    const code = (err as any)?.code ?? "invalid_format";
    // deno-lint-ignore no-explicit-any
    const msg = (err as any)?.message ?? String(err);
    return reply(status, {
      ok: false,
      error: { code, message: msg },
    });
  }

  // 4. Authorisation — caller must manage the from-team.
  const { data: isManager, error: authzErr } = await asUser.rpc(
    "is_team_manager",
    { p_team_id: fromTeamId },
  );
  if (authzErr) {
    return reply(500, {
      ok: false,
      error: { code: "authz_failed", message: authzErr.message },
    });
  }
  if (isManager !== true) {
    return reply(403, {
      ok: false,
      error: {
        code: "forbidden",
        message:
          "Only managers of the requesting team can send a match request",
      },
    });
  }

  // 5. Atomic write — single Postgres transaction.
  const sql = db();
  try {
    const out = await sql.begin(async (tx) => {
      // Block duplicates only when targeted — open requests can stack.
      if (toTeamId !== null) {
        const dupRows = await tx`
          select 1 from match_challenges
           where from_team_id = ${fromTeamId}
             and to_team_id   = ${toTeamId}
             and status in ('pending', 'countered')
           limit 1`;
        if (dupRows.length > 0) {
          throw new HttpSignal(
            409,
            "duplicate_pending",
            "A pending request already exists for these teams",
          );
        }
      }

      // Mint a unique 6-digit code; retry on collision up to 6 times.
      let inserted: Record<string, unknown> | null = null;
      let attempts = 0;
      while (inserted === null) {
        const code = mintCode();
        try {
          const rows = await tx`
            insert into match_challenges (
              from_team_id, to_team_id, requested_by,
              proposed_start_time, proposed_venue,
              proposed_format_code, proposed_format, message,
              share_code, code_expires_at, proposal_expires_at
            ) values (
              ${fromTeamId},
              ${toTeamId},
              ${actor},
              ${proposedStartTime},
              ${proposedVenue},
              ${validatedFormat.code},
              ${tx.json(validatedFormat.rules)},
              ${message},
              ${code},
              now() + interval '24 hours',
              now() + interval '48 hours'
            )
            returning request_id, share_code, code_expires_at,
                      proposal_expires_at`;
          inserted = rows[0];
        } catch (e) {
          // deno-lint-ignore no-explicit-any
          const code = (e as any)?.code;
          attempts += 1;
          if (code !== "23505" || attempts >= 6) throw e;
        }
      }
      return inserted!;
    });

    return reply(200, {
      ok: true,
      request_id: out.request_id,
      share_code: out.share_code,
      code_expires_at: out.code_expires_at,
      proposal_expires_at: out.proposal_expires_at,
    });
  } catch (e) {
    if (e instanceof HttpSignal) {
      return reply(e.status, {
        ok: false,
        error: { code: e.code, message: e.message },
      });
    }
    console.error("send-match-request failed:", e);
    return reply(500, {
      ok: false,
      error: { code: "write_failed", message: String(e) },
    });
  }
});
