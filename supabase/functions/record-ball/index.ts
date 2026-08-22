// record-ball — store one delivery. NO CRICKET HAPPENS HERE.
//
// 🟥 Read this before adding anything: the rules of cricket live in exactly ONE
// place, the Dart engine on the scoring device (lib/features/matches/domain/
// scoring/), specified by _shared/scoring/vectors.json. That device has to
// compute an innings unaided while it has no signal, so it is the authority on
// the arithmetic. This function used to recompute every delivery with a second
// engine, and a database trigger recomputed it with a third; the three
// disagreed silently and the scorecard was the casualty.
// See docs/offline-scoring-design.md §7, §13, D10/D11/D13.
//
// So this function does four things, none of which need the Laws:
//   1. WRITER    — may this account score THIS innings? (batting side, D12)
//   2. LIVENESS  — is the match still open?
//   3. DUPLICATE — have I stored this delivery before? (idempotency key, D7)
//   4. STORE     — insert the delivery exactly as the device computed it, then
//                  re-derive the innings aggregates by SUMMING the ledger.
//
// (4) is D13: totals are DERIVED, never accumulated. That is what makes undo
// "delete the last row and re-total" instead of "carefully subtract", and it
// means a replayed or repaired ledger always produces consistent totals.
//
// The one piece of cricket that stays server-side is the MATCH RESULT, and
// deliberately: §19.4 forbids the device from ever declaring a winner. A score
// may be provisional; a result may not. The device tells us the innings ended;
// we decide what that means for the match.
//
// Responses:
//   200 { ok:true, ball, innings, transition }  — stored (or already stored)
//   401/403 { ok:false, error }  — not signed in / not this innings' scorer
//   409 { ok:false, error }      — innings not started, or match already closed
//   400 { ok:false, error }      — malformed request

import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { db, userClient } from "../_shared/db.ts";
import { corsPreflight, json } from "../_shared/http.ts";
import { computeResult, type InningsLine } from "../_shared/scoring/result.ts";

/** Thrown inside the transaction to roll back and return a specific status. */
class HttpSignal {
  constructor(
    readonly status: number,
    readonly code: string,
    readonly message: string,
  ) {}
}

Deno.serve(async (req) => {
  // CORS preflight answers BEFORE the auth gate — the browser sends OPTIONS
  // with no Authorization header, so the bearer check would 401 it and the
  // real POST would never fire.
  if (req.method === "OPTIONS") return corsPreflight();

  const authHeader = req.headers.get("Authorization") ?? "";
  if (!authHeader.startsWith("Bearer ")) {
    return json(401, {
      ok: false,
      error: { code: "unauthenticated", message: "Missing bearer token" },
    });
  }

  const asUser = userClient(authHeader);
  const actor = await identifyActor(asUser);
  if (!actor) {
    return json(401, {
      ok: false,
      error: { code: "unauthenticated", message: "Invalid session" },
    });
  }

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return json(400, {
      ok: false,
      error: { code: "bad_json", message: "Body is not JSON" },
    });
  }

  const matchId = body.p_match_id as string;
  const inningsNumber = Number(body.p_innings_number);
  const idempotencyKey = body.p_idempotency_key as string | undefined;

  if (!matchId || !Number.isFinite(inningsNumber)) {
    return json(400, {
      ok: false,
      error: {
        code: "bad_request",
        message: "p_match_id and p_innings_number are required",
      },
    });
  }
  // The idempotency key is the device's op id. Without it a retry after a
  // dropped connection records the delivery twice, which is precisely the
  // failure the offline queue makes likely rather than rare.
  if (!idempotencyKey) {
    return json(400, {
      ok: false,
      error: {
        code: "idempotency_key_required",
        message: "p_idempotency_key is required so retries cannot double-record",
      },
    });
  }

  const sql = db();

  try {
    const out = await sql.begin(async (tx) => {
      // These are pooled connections shared across requests, so auth.uid() has
      // to be set from the token we just verified. `true` = transaction-local:
      // a session-scoped setting would leak this scorer's identity into the
      // next request on the same connection.
      await tx`
        select set_config(
          'request.jwt.claims',
          ${JSON.stringify({ sub: actor, role: "authenticated" })},
          true
        )`;

      // ── 1. WRITER ───────────────────────────────────────────────────────
      // The batting side scores its own innings; control passes at the break.
      // The innings number is part of the question, not decoration.
      const authzRows = await tx`
        select public._can_score_innings(${matchId}::uuid, ${inningsNumber}::integer) as allowed`;
      if (authzRows[0]?.allowed !== true) {
        throw new HttpSignal(
          403,
          "forbidden",
          "Only the batting side can score this innings",
        );
      }

      // Lock the innings row for the rest of the transaction. Not a version
      // guard — it serialises `seq` assignment against a concurrent write.
      const stateRows = await tx`
        select innings_id, version
          from match_innings_state
         where match_id = ${matchId} and innings_number = ${inningsNumber}
         for update`;
      if (stateRows.length === 0) {
        throw new HttpSignal(
          409,
          "innings_not_started",
          "Innings has not been started for this match",
        );
      }
      const inningsId = stateRows[0].innings_id as string;

      // ── 2. LIVENESS ─────────────────────────────────────────────────────
      const matchRows = await tx`
        select status, toss_won_by, toss_decision, team_a_id, team_b_id, format
          from matches where match_id = ${matchId}`;
      const m = matchRows[0];
      if (
        m && ["completed", "abandoned", "walkover"].includes(m.status as string)
      ) {
        throw new HttpSignal(409, "match_finalised", "Match is already finished");
      }

      // ── 3. DUPLICATE + 4. STORE ─────────────────────────────────────────
      // One statement does both: the unique (innings_id, idempotency_key)
      // constraint turns a retry into a no-op instead of a second delivery.
      const nextSeqRows = await tx`
        select coalesce(max(seq), 0) + 1 as next_seq
          from match_deliveries where innings_id = ${inningsId}`;
      const nextSeq = Number(nextSeqRows[0]?.next_seq ?? 1);

      // Every column below is the DEVICE's answer, stored as given. Nothing
      // here is recomputed or second-guessed.
      const inserted = await tx`
        insert into match_deliveries (
          innings_id, match_id, innings_number, seq,
          over_number, ball_in_over, is_legal_delivery, delivery_type, ball_type,
          runs_off_bat, runs_scored, extra_runs, extras, is_free_hit,
          is_wicket, wicket_type, is_four, is_six, is_boundary,
          striker_id, non_striker_id, bowler_id, batsman_id, fielder_id,
          idempotency_key, commentary, recorded_by, created_by
        ) values (
          ${inningsId}, ${matchId}, ${inningsNumber}, ${nextSeq},
          ${num(body.p_over_number, 0)}, ${num(body.p_ball_in_over, 0)},
          ${body.p_is_legal_delivery === true},
          ${(body.p_ball_type as string) ?? "legal"},
          ${(body.p_ball_type as string) ?? "legal"},
          ${num(body.p_runs_scored, 0)}, ${num(body.p_runs_scored, 0)},
          ${num(body.p_extras, 0)}, ${num(body.p_extras, 0)},
          ${body.p_is_free_hit === true},
          ${body.p_is_wicket === true},
          ${(body.p_wicket_type as string) ?? null},
          ${num(body.p_runs_scored, 0) === 4}, ${num(body.p_runs_scored, 0) === 6},
          ${num(body.p_runs_scored, 0) === 4 || num(body.p_runs_scored, 0) === 6},
          ${(body.p_batsman_id as string) ?? null},
          ${(body.p_non_striker_id as string) ?? null},
          ${(body.p_bowler_id as string) ?? null},
          ${(body.p_batsman_id as string) ?? null},
          ${(body.p_fielder_id as string) ?? null},
          ${idempotencyKey}, ${(body.p_commentary as string) ?? null},
          ${actor}, ${actor}
        )
        on conflict (innings_id, idempotency_key) do nothing
        returning *`;

      let ball = inserted[0];
      let alreadyStored = false;
      if (!ball) {
        // Seen before. Return what we already hold — a retry must be a no-op,
        // not an error, or the device's queue stalls on a delivery that landed.
        alreadyStored = true;
        const existing = await tx`
          select * from match_deliveries
           where innings_id = ${inningsId} and idempotency_key = ${idempotencyKey}`;
        ball = existing[0];
      }

      if (!alreadyStored && body.p_is_wicket === true && body.p_wicket_type) {
        await tx`
          insert into match_wickets (
            delivery_id, innings_id, player_out_id, dismissal_kind,
            is_bowler_credited, credited_bowler_id, primary_fielder_id,
            fall_of_wicket_score, fall_of_wicket_number, fall_of_wicket_overs
          )
          select
            ${ball.delivery_id}, ${inningsId},
            ${(body.p_dismissed_player_id as string) ?? (body.p_batsman_id as string)},
            ${body.p_wicket_type as string},
            ${body.p_is_bowler_credited === true},
            ${(body.p_bowler_id as string) ?? null},
            ${(body.p_fielder_id as string) ?? null},
            -- Fall of wicket is read off the ledger, not sent: it is the score
            -- at this delivery, which the ledger already knows.
            coalesce(sum(d.runs_off_bat + d.extra_runs), 0)::int,
            count(*) filter (where d.is_wicket)::int,
            round(
              (count(*) filter (where d.is_legal_delivery))::numeric
              / greatest(${num(body.p_balls_per_over, 6)}, 1), 1
            )
          from match_deliveries d
          where d.innings_id = ${inningsId} and d.is_undone = false
          on conflict do nothing`;
      }

      // ── Re-derive the innings from the ledger (D13) ──────────────────────
      // Aggregates are SUMMED, never incremented. The on-field trio and the
      // all-out flag are not sums — they come from the engine that computed
      // the delivery, which is the device.
      const updatedState = await tx`
        update match_innings_state s set
          total_runs       = agg.runs,
          total_wickets    = agg.wickets,
          legal_ball_count = agg.legal,
          total_wides      = agg.wides,
          total_no_balls   = agg.no_balls,
          total_byes       = agg.byes,
          total_leg_byes   = agg.leg_byes,
          total_penalties  = agg.penalties,
          striker_id       = ${(body.p_striker_after as string) ?? null},
          non_striker_id   = ${(body.p_non_striker_after as string) ?? null},
          bowler_id        = ${(body.p_bowler_after as string) ?? null},
          is_all_out       = ${body.p_is_all_out === true},
          version          = s.version + 1,
          updated_at       = now()
        from (
          select
            coalesce(sum(runs_off_bat + extra_runs), 0)::int          as runs,
            (count(*) filter (where is_wicket))::int                  as wickets,
            (count(*) filter (where is_legal_delivery))::int          as legal,
            coalesce(sum(extra_runs) filter (where delivery_type = 'wide'), 0)::int     as wides,
            coalesce(sum(extra_runs) filter (where delivery_type = 'no_ball'), 0)::int  as no_balls,
            coalesce(sum(extra_runs) filter (where delivery_type = 'bye'), 0)::int      as byes,
            coalesce(sum(extra_runs) filter (where delivery_type = 'leg_bye'), 0)::int  as leg_byes,
            coalesce(sum(extra_runs) filter (where delivery_type = 'penalty'), 0)::int  as penalties
          from match_deliveries
          where innings_id = ${inningsId} and is_undone = false
        ) agg
        where s.innings_id = ${inningsId}
        returning s.*`;

      // ── Innings termination ─────────────────────────────────────────────
      // The DEVICE decides the innings ended — that is a rule, and rules live
      // there. What the match becomes as a result is decided here, because
      // §19.4 forbids a result ever being rendered from local computation.
      let transition: {
        kind: "none" | "innings_break" | "completed";
        result?: unknown;
      } = { kind: "none" };

      if (body.p_innings_ended === true && !alreadyStored) {
        const fmt = (m?.format ?? {}) as Record<string, unknown>;
        const inningsPerSide = Math.max(num(fmt.innings_per_side, 1), 1);
        const isFinalInnings = inningsNumber >= inningsPerSide * 2;

        if (!isFinalInnings) {
          await tx`
            update matches set status = 'innings_break', updated_at = now()
             where match_id = ${matchId}`;
          transition = { kind: "innings_break" };
        } else {
          const innRows = await tx`
            select innings_number, total_runs, total_wickets, legal_ball_count,
                   is_all_out
              from match_innings_state
             where match_id = ${matchId}
             order by innings_number`;
          const res = computeResult(toInningsLines(innRows, m), {
            oversPerInnings: num(fmt.overs_per_innings, 0),
            playersPerTeam: num(fmt.players_per_team, 11),
            ballsPerOver: num(fmt.balls_per_over, 6),
            maxOversPerBowler: num(fmt.max_overs_per_bowler, 0),
            inningsPerSide,
            ballType: (fmt.ball_type as "leather" | "tape" | "tennis") ?? "leather",
            wicketsToAllOut: fmt.wickets_to_all_out != null
              ? Number(fmt.wickets_to_all_out)
              : undefined,
          });
          await tx`
            update matches set
              status   = 'completed',
              end_time = now(),
              updated_at = now(),
              result   = ${
            tx.json({
              winner_team_id: res.winnerTeamId,
              win_type: res.winType,
              win_margin: res.winMargin,
              // `description` is the key MatchDto reads into resultDescription.
              description: res.description,
              summary: res.description,
            })
          }
             where match_id = ${matchId}`;
          transition = { kind: "completed", result: res };
        }
      }

      return {
        ball,
        innings: updatedState[0] ?? null,
        transition,
        duplicate: alreadyStored,
      };
    });

    return json(200, {
      ok: true,
      ball: out.ball,
      innings: out.innings,
      transition: out.transition,
      duplicate: out.duplicate,
    });
  } catch (e) {
    if (e instanceof HttpSignal) {
      return json(e.status, {
        ok: false,
        error: { code: e.code, message: e.message },
      });
    }
    console.error("record-ball failed:", e);
    return json(500, {
      ok: false,
      error: { code: "write_failed", message: String(e) },
    });
  }
});

/// The caller's user id from a verified JWT, or null.
///
/// Prefers getClaims (local signature verification against a cached JWKS).
/// Older supabase-js builds do not expose it, so getUser remains the fallback
/// — correct, just a round trip slower.
// deno-lint-ignore no-explicit-any
async function identifyActor(asUser: any): Promise<string | null> {
  try {
    if (typeof asUser?.auth?.getClaims === "function") {
      const { data, error } = await asUser.auth.getClaims();
      const sub = data?.claims?.sub;
      if (!error && typeof sub === "string" && sub.length > 0) return sub;
    }
  } catch (e) {
    console.warn("record-ball: getClaims unavailable, falling back:", e);
  }
  const { data, error } = await asUser.auth.getUser();
  return error ? null : (data?.user?.id ?? null);
}

function num(v: unknown, fallback: number): number {
  const n = Number(v);
  return Number.isFinite(n) ? n : fallback;
}

// Map innings_state rows → result InningsLine[], deriving each innings's batting
// team from the toss (odd innings = bats-first team). Mirrors _can_score_innings
// so the writer rule and the result agree about who batted when.
// deno-lint-ignore no-explicit-any
function toInningsLines(rows: any[], m: any): InningsLine[] {
  const teamA = (m?.team_a_id ?? null) as string | null;
  const teamB = (m?.team_b_id ?? null) as string | null;
  const tossWon = (m?.toss_won_by ?? null) as string | null;
  const decision = (m?.toss_decision ?? null) as string | null;
  const batsFirst = tossWon && decision
    ? (decision === "bat" ? tossWon : (tossWon === teamA ? teamB : teamA))
    : teamA;
  const other = batsFirst === teamA ? teamB : teamA;
  return rows.map((r) => {
    const n = Number(r.innings_number);
    return {
      inningsNumber: n,
      battingTeamId: (n % 2 === 1 ? batsFirst : other) ?? "",
      runs: Number(r.total_runs),
      wickets: Number(r.total_wickets),
      legalBalls: Number(r.legal_ball_count),
      isAllOut: r.is_all_out === true,
    };
  });
}
