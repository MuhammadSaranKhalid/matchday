// cricket-match-action
//
// Phase 2B extends the Phase-2A command boundary with tournament operations
// that mutate match-visible state. PostgreSQL owns authorization/persistence;
// this function publishes the canonical snapshot to Ably after commit.

import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { corsPreflight, json } from "../_shared/http.ts";
import { db } from "../_shared/db.ts";
import {
  authenticateRequest,
  setTransactionJwtClaims,
} from "../record-ball/services/auth_service.ts";

type Action =
  | "record_toss_winner"
  | "record_toss_decision"
  | "submit_match_openers"
  | "start_match_now"
  | "start_innings"
  | "undo_last_ball"
  | "complete_cricket_match"
  | "tournament_reschedule_match"
  | "tournament_abandon_match"
  | "tournament_declare_walkover"
  | "tournament_override_result"
  | "tournament_revise_match_conditions"
  | "tournament_trigger_super_over";

type Body = {
  action?: Action;
  p_match_id?: string;

  // Cricket start/scoring.
  p_won_by?: string;
  p_face?: string | null;
  p_decision?: "bat" | "bowl";
  p_striker_id?: string;
  p_non_striker_id?: string;
  p_bowler_id?: string;
  p_innings_number?: number;
  p_target?: number | null;
  p_description?: string;

  // Tournament match operations.
  p_start?: string;
  p_venue?: string | null;
  p_mode?: string;
  p_reschedule_to?: string | null;
  p_reason?: string | null;
  p_winner_team_id?: string;
  p_revised_overs?: number;
  p_bowler_quota?: number;
  p_revised_target?: number | null;
  p_method?: string;
  p_bats_first_id?: string;
};

const allowed: Action[] = [
  "record_toss_winner",
  "record_toss_decision",
  "submit_match_openers",
  "start_match_now",
  "start_innings",
  "undo_last_ball",
  "complete_cricket_match",
  "tournament_reschedule_match",
  "tournament_abandon_match",
  "tournament_declare_walkover",
  "tournament_override_result",
  "tournament_revise_match_conditions",
  "tournament_trigger_super_over",
];

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return corsPreflight();

  const auth = await authenticateRequest(req);
  if (auth.error || !auth.actorId) {
    return json(auth.error?.status ?? 401, {
      ok: false,
      error: {
        code: auth.error?.code ?? "UNAUTHENTICATED",
        message: auth.error?.message ?? "Invalid or missing session",
      },
    });
  }

  let body: Body;
  try {
    body = await req.json();
  } catch {
    return json(400, {
      ok: false,
      error: { code: "BAD_REQUEST", message: "Invalid JSON body" },
    });
  }

  if (!body.action || !allowed.includes(body.action)) {
    return json(400, {
      ok: false,
      error: {
        code: "UNKNOWN_ACTION",
        message: `Unsupported action: ${body.action}`,
      },
    });
  }

  if (!body.p_match_id) {
    return json(400, {
      ok: false,
      error: { code: "BAD_REQUEST", message: "p_match_id is required" },
    });
  }

  const action = body.action;
  const matchId = body.p_match_id;
  const sql = db();

  try {
    const out = await sql.begin(async (tx) => {
      await setTransactionJwtClaims(tx, auth.actorId!);

      let result: unknown = null;
      let inningsNumber: number | null = null;

      switch (action) {
        case "record_toss_winner":
          requireValue(body.p_won_by, "p_won_by");
          await tx`
            select public.record_toss_winner(
              ${matchId}::uuid,
              ${body.p_won_by}::uuid,
              ${body.p_face ?? null}::char
            )`;
          break;

        case "record_toss_decision":
          requireValue(body.p_decision, "p_decision");
          await tx`
            select public.record_toss_decision(
              ${matchId}::uuid,
              ${body.p_decision}::public.toss_decision
            )`;
          break;

        case "submit_match_openers":
          requireValue(body.p_striker_id, "p_striker_id");
          requireValue(body.p_non_striker_id, "p_non_striker_id");
          inningsNumber = 1;
          await tx`
            select public.submit_match_openers(
              ${matchId}::uuid,
              ${body.p_striker_id}::uuid,
              ${body.p_non_striker_id}::uuid
            )`;
          break;

        case "start_match_now":
          inningsNumber = 1;
          await tx`select public.start_match_now(${matchId}::uuid)`;
          break;

        case "start_innings":
          requireValue(body.p_striker_id, "p_striker_id");
          requireValue(body.p_non_striker_id, "p_non_striker_id");
          requireValue(body.p_bowler_id, "p_bowler_id");
          requireInteger(body.p_innings_number, "p_innings_number");
          inningsNumber = body.p_innings_number!;
          await tx`
            select public.start_innings(
              ${matchId}::uuid,
              ${inningsNumber}::integer,
              ${body.p_striker_id}::uuid,
              ${body.p_non_striker_id}::uuid,
              ${body.p_bowler_id}::uuid,
              ${body.p_target ?? null}::integer
            )`;
          break;

        case "undo_last_ball": {
          requireInteger(body.p_innings_number, "p_innings_number");
          inningsNumber = body.p_innings_number!;
          const rows = await tx`
            select public.undo_last_ball(
              ${matchId}::uuid,
              ${inningsNumber}::integer
            ) as undone`;
          result = rows[0]?.undone === true;
          break;
        }

        case "complete_cricket_match":
          requireValue(body.p_description, "p_description");
          await tx`
            select public.complete_cricket_match(
              ${matchId}::uuid,
              ${body.p_description!.trim()}
            )`;
          break;

        case "tournament_reschedule_match":
          requireValue(body.p_start, "p_start");
          await tx`
            select public.tournament_reschedule_match(
              ${matchId}::uuid,
              ${body.p_start}::timestamptz,
              ${body.p_venue ?? null}::text
            )`;
          break;

        case "tournament_abandon_match":
          requireValue(body.p_mode, "p_mode");
          await tx`
            select public.tournament_abandon_match(
              ${matchId}::uuid,
              ${body.p_mode}::text,
              ${body.p_reschedule_to ?? null}::timestamptz,
              ${body.p_reason ?? null}::text
            )`;
          break;

        case "tournament_declare_walkover":
          requireValue(body.p_winner_team_id, "p_winner_team_id");
          await tx`
            select public.tournament_declare_walkover(
              ${matchId}::uuid,
              ${body.p_winner_team_id}::uuid,
              ${body.p_reason ?? null}::text
            )`;
          break;

        case "tournament_override_result":
          requireValue(body.p_winner_team_id, "p_winner_team_id");
          requireValue(body.p_reason, "p_reason");
          await tx`
            select public.tournament_override_result(
              ${matchId}::uuid,
              ${body.p_winner_team_id}::uuid,
              ${body.p_reason}::text
            )`;
          break;

        case "tournament_revise_match_conditions":
          requireInteger(body.p_revised_overs, "p_revised_overs");
          requireInteger(body.p_bowler_quota, "p_bowler_quota");
          requireValue(body.p_method, "p_method");
          await tx`
            select public.tournament_revise_match_conditions(
              ${matchId}::uuid,
              ${body.p_revised_overs}::integer,
              ${body.p_bowler_quota}::integer,
              ${body.p_revised_target ?? null}::integer,
              ${body.p_method}::text,
              ${body.p_reason ?? null}::text
            )`;
          break;

        case "tournament_trigger_super_over":
          requireValue(body.p_bats_first_id, "p_bats_first_id");
          await tx`
            select public.tournament_trigger_super_over(
              ${matchId}::uuid,
              ${body.p_bats_first_id}::uuid
            )`;
          break;
      }

      const matchRows = await tx`
        select *
          from public.cricket_match_details
         where match_id = ${matchId}::uuid`;

      const match = matchRows[0] ?? null;

      let innings: unknown = null;
      if (inningsNumber != null) {
        const inningsRows = await tx`
          select *
            from public.match_innings_state
           where match_id = ${matchId}::uuid
             and innings_number = ${inningsNumber}
           limit 1`;
        innings = inningsRows[0] ?? null;
      }

      return { result, match, innings, inningsNumber };
    });

    await publish(matchId, action, out);

    return json(200, {
      ok: true,
      result: out.result,
      match: out.match,
      innings: out.innings,
    });
  } catch (e) {
    if (e instanceof InputError) {
      return json(400, {
        ok: false,
        error: { code: "BAD_REQUEST", message: e.message },
      });
    }

    const err = normalizeDbError(e);
    console.error("[cricket-match-action]", action, err);
    return json(err.status, {
      ok: false,
      error: { code: err.code, message: err.message },
    });
  }
});

class InputError extends Error {}

function requireValue(value: unknown, name: string): asserts value {
  if (value == null || (typeof value === "string" && value.trim() === "")) {
    throw new InputError(`${name} is required`);
  }
}

function requireInteger(value: unknown, name: string): asserts value is number {
  if (!Number.isInteger(value)) {
    throw new InputError(`${name} must be an integer`);
  }
}

function normalizeDbError(e: unknown): {
  status: number;
  code: string;
  message: string;
} {
  const raw = e as { code?: string; message?: string; detail?: string };
  const code = raw?.code ?? "DATABASE_ERROR";
  const message =
    raw?.message ?? raw?.detail ?? (e instanceof Error ? e.message : String(e));

  if (code === "42501" || code === "28000") {
    return { status: 403, code, message };
  }
  if (code === "P0002") {
    return { status: 404, code, message };
  }
  if (
    code === "22023" ||
    code === "23514" ||
    code === "23502" ||
    code === "23000"
  ) {
    return { status: 422, code, message };
  }
  return { status: 500, code, message };
}

async function publish(
  matchId: string,
  action: Action,
  out: {
    match: unknown;
    innings: unknown;
    inningsNumber: number | null;
  },
): Promise<void> {
  const key = Deno.env.get("ABLY_API_KEY");
  if (!key) {
    console.warn("[cricket-match-action] ABLY_API_KEY not configured");
    return;
  }

  try {
    const Ably = (await import("npm:ably@2.4.1")).default;
    const ably = new Ably.Rest(key);

    if (out.match) {
      await ably.channels
        .get(`match:${matchId}:state`)
        .publish("match_state_updated", out.match);
    }

    if (out.innings) {
      await ably.channels
        .get(`match:${matchId}:state`)
        .publish("innings_state_updated", out.innings);
    }

    if (action === "undo_last_ball" && out.inningsNumber != null) {
      await ably.channels
        .get(`match:${matchId}:balls`)
        .publish("balls_resync", { innings_number: out.inningsNumber });
    }
  } catch (e) {
    // Persistence is authoritative. Realtime failure never rolls it back.
    console.error("[cricket-match-action] Ably publish failed:", e);
  }
}
