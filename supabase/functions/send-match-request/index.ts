// send-match-request — edge orchestrator for the Match Challenge send flow.
//
// Mirrors the existing `public.send_match_request` SECURITY DEFINER PG
// function (migration 0600 lines 263–350) but in TypeScript so we can iterate
// the orchestration (validation copy, future push-notification fan-out,
// analytics) without DB migrations while the request flow is still settling.
// The PG function stays in place as a fallback / direct-DB caller.
//
// Flow:
//   1. identify the caller (JWT → actor)
//   2. parse + shallow-validate the body
//   3. authorise: caller must manage `p_from_team_id`
//      (reuses the existing `is_team_manager` PG helper)
//   4. one Postgres transaction:
//        validate the picked XI (`_validate_team_xi` helper) →
//        block duplicates for targeted requests →
//        mint a unique 6-digit share code (retry up to 6 times) →
//        insert the row with a 24h code expiry + 48h proposal expiry →
//        commit
//   5. return { ok: true, request_id, share_code, ... }
//
// Responses:
//   200 { ok:true, request_id, share_code, code_expires_at, proposal_expires_at }
//   400 { ok:false, error }     — body parse / shape failure
//   401 { ok:false, error }     — missing / invalid bearer token
//   403 { ok:false, error }     — caller is not a manager of the from-team
//   409 { ok:false, error }     — duplicate pending request between these teams
//   422 { ok:false, error }     — validation rejected (bad XI, bad pps, etc.)
//   500 { ok:false, error }     — DB / unexpected failure
//
// Body shape (same p_* keys as the RPC, so the Flutter side can swap the
// transport without renaming anything):
//   {
//     p_from_team_id:        uuid,
//     p_to_team_id?:         uuid,           // null/missing → open challenge
//     p_proposed_start_time?: string (ISO-8601),
//     p_proposed_venue?:     string,
//     p_proposed_format?:    jsonb (MatchFormat shape),
//     p_message?:            string,
//     p_players_per_side?:   integer (5..15, default 11),
//     p_from_team_xi?:       uuid[],
//     p_from_team_keeper_id?: uuid,
//   }

import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { db, userClient } from "../_shared/db.ts";
import { json } from "../_shared/http.ts";

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
  // 6-digit zero-padded numeric code, identical to the SQL function's
  // `lpad((floor(random()*1000000))::int::text, 6, '0')`.
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
  const message = (body.p_message as string | null | undefined) ?? null;
  const playersPerSide = Number(body.p_players_per_side ?? 11);
  const fromTeamXi = Array.isArray(body.p_from_team_xi)
    ? (body.p_from_team_xi as string[])
    : [];
  const fromTeamKeeperId =
    (body.p_from_team_keeper_id as string | null | undefined) ?? null;

  // Shallow shape checks — the transaction picks up the rest.
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
  if (!Number.isFinite(playersPerSide) || playersPerSide < 5 ||
      playersPerSide > 15) {
    return reply(422, {
      ok: false,
      error: {
        code: "invalid_players_per_side",
        message: "players_per_side must be between 5 and 15",
      },
    });
  }
  if (fromTeamXi.length > playersPerSide) {
    return reply(422, {
      ok: false,
      error: {
        code: "xi_too_large",
        message: "from_team_xi has more players than players_per_side",
      },
    });
  }
  for (const id of fromTeamXi) {
    if (!UUID_RE.test(id)) {
      return reply(400, {
        ok: false,
        error: {
          code: "bad_request",
          message: "p_from_team_xi must be an array of uuids",
        },
      });
    }
  }
  if (fromTeamKeeperId !== null && !UUID_RE.test(fromTeamKeeperId)) {
    return reply(400, {
      ok: false,
      error: {
        code: "bad_request",
        message: "p_from_team_keeper_id must be a uuid or null",
      },
    });
  }
  if (fromTeamKeeperId !== null && !fromTeamXi.includes(fromTeamKeeperId)) {
    return reply(422, {
      ok: false,
      error: {
        code: "keeper_not_in_xi",
        message: "Wicket-keeper must be part of the picked XI",
      },
    });
  }

  // 3. Authorisation — caller must manage the from-team. Run AS the user so
  //    `is_team_manager` reads `auth.uid()` from the caller's JWT.
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

  // players_per_side is the single source of truth. The match_requests
  // `players_per_side` column is now a generated projection of
  // proposed_format->>'players_per_team' (migration
  // match_requests_pps_single_source), and a CHECK requires the key to be
  // present (5..15). Fold it in here and never write the generated column.
  const proposedFormat = {
    ...proposedFormatInput,
    players_per_team: playersPerSide,
  };

  // 4. Atomic write — single Postgres transaction over the pooled connection.
  const sql = db();
  try {
    const out = await sql.begin(async (tx) => {
      // Reuse the existing SECURITY DEFINER helper. Raises with errcode 23514
      // ("Player X is not an active member of team Y") on the first mismatch.
      await tx`select public._validate_team_xi(
        ${fromTeamId}::uuid,
        ${fromTeamXi.length ? fromTeamXi : null}::uuid[]
      )`;

      // Block duplicates only when targeted — open requests can stack
      // (manager might want multiple parallel codes if they mistype or
      // change ground). Mirrors the SQL function exactly.
      if (toTeamId !== null) {
        const dupRows = await tx`
          select 1 from match_requests
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
            insert into match_requests (
              from_team_id, to_team_id, requested_by,
              proposed_start_time, proposed_venue, proposed_format, message,
              from_team_xi, from_team_keeper_id,
              share_code, code_expires_at, proposal_expires_at
            ) values (
              ${fromTeamId},
              ${toTeamId},
              ${actor},
              ${proposedStartTime},
              ${proposedVenue},
              ${tx.json(proposedFormat)},
              ${message},
              ${fromTeamXi.length ? fromTeamXi : []}::uuid[],
              ${fromTeamKeeperId},
              ${code},
              now() + interval '24 hours',
              now() + interval '48 hours'
            )
            returning request_id, share_code, code_expires_at,
                      proposal_expires_at`;
          inserted = rows[0];
        } catch (e) {
          // postgres.js maps `unique_violation` to error.code === '23505'.
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
    // postgres.js raises with `code` for PG errors. Surface the validation
    // ones (raised by `_validate_team_xi`) as 422 with the original message.
    // deno-lint-ignore no-explicit-any
    const code = (e as any)?.code as string | undefined;
    if (code === "23514") {
      return reply(422, {
        ok: false,
        error: {
          code: "invalid_xi",
          // deno-lint-ignore no-explicit-any
          message: String((e as any)?.message ?? "Invalid XI"),
        },
      });
    }
    console.error("send-match-request failed:", e);
    return reply(500, {
      ok: false,
      error: { code: "write_failed", message: String(e) },
    });
  }
});
