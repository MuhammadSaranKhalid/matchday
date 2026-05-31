// record-ball — edge orchestrator (all-TypeScript write path).
//
// Flow:
//   1. identify the caller (JWT → actor)
//   2. authorize with the EXISTING _can_score_match() rule, run AS the user
//   3. open ONE Postgres transaction over a direct connection:
//        lock the innings row (FOR UPDATE) → read state/format/prev delivery →
//        compute the ball with the pure engine → insert balls + update
//        innings_state → and, if the engine says the innings ENDED, transition
//        the match (innings_break, or completed with a computed result) → commit
//
// The lock + transaction live here in TypeScript (a direct Postgres connection),
// not in a SQL function — PostgREST/supabase-js has no transactions. The
// per-table triggers (broadcast_new_ball, broadcast_innings_state,
// broadcast_match_state, _after_match_complete) fire on these writes, so realtime
// + standings/bracket advance work unchanged.
//
// Responses:
//   200 { ok:true, ball, events, transition }  — written (transition tells the
//          client to go to innings-break / result; kind: none|innings_break|completed)
//   422 { ok:false, error }          — engine rejected the delivery
//   409 { ok:false, conflict:true }  — version moved (another scorer); retry
//   401/403 { ok:false, error }      — not signed in / not allowed to score

import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { db, userClient } from "../_shared/db.ts";
import { json } from "../_shared/http.ts";
import { applyBall } from "../_shared/scoring/engine.ts";
import { computeResult, type InningsLine } from "../_shared/scoring/result.ts";
import type {
  BallInput,
  BallKind,
  InningsState,
  MatchFormat,
} from "../_shared/scoring/types.ts";

/** Thrown inside the transaction to roll back and return a specific status. */
class HttpSignal {
  constructor(
    readonly status: number,
    readonly code: string,
    readonly message: string,
  ) {}
}
/** Thrown inside the transaction when the optimistic version guard trips. */
class ConflictSignal {}

Deno.serve(async (req) => {
  const authHeader = req.headers.get("Authorization") ?? "";
  if (!authHeader.startsWith("Bearer ")) {
    return json(401, {
      ok: false,
      error: { code: "unauthenticated", message: "Missing bearer token" },
    });
  }

  // 1. Identify the caller.
  const asUser = userClient(authHeader);
  const { data: userData, error: userErr } = await asUser.auth.getUser();
  const actor = userData?.user?.id;
  if (userErr || !actor) {
    return json(401, {
      ok: false,
      error: { code: "unauthenticated", message: "Invalid session" },
    });
  }

  // 2. Parse (same p_* shape as record_ball).
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
  if (!matchId || !Number.isFinite(inningsNumber)) {
    return json(400, {
      ok: false,
      error: {
        code: "bad_request",
        message: "p_match_id and p_innings_number are required",
      },
    });
  }
  const expectedVersion = body.p_expected_version != null
    ? Number(body.p_expected_version)
    : null;

  // 3. Authorize via the existing server-side rule, run AS the user.
  const { data: canScore, error: authzErr } = await asUser.rpc(
    "_can_score_match",
    { p_match_id: matchId },
  );
  if (authzErr) {
    return json(500, {
      ok: false,
      error: { code: "authz_failed", message: authzErr.message },
    });
  }
  if (canScore !== true) {
    return json(403, {
      ok: false,
      error: {
        code: "forbidden",
        message: "Only organisers or assigned scorers can score this match",
      },
    });
  }

  const sql = db();

  // 4. One atomic transaction: lock → read → compute → write → maybe transition.
  try {
    const out = await sql.begin(async (tx) => {
      const stateRows = await tx`
        select striker_id, non_striker_id, bowler_id, legal_ball_count,
               total_runs, total_wickets, total_extras, is_all_out,
               is_declared, target, version
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
      const s = stateRows[0];

      // Double-commit guard.
      if (expectedVersion !== null && Number(s.version) !== expectedVersion) {
        throw new ConflictSignal();
      }

      const matchRows = await tx`
        select format, status, toss_won_by, toss_decision, team_a_id, team_b_id
          from matches where match_id = ${matchId}`;
      const m = matchRows[0];
      if (
        m && ["completed", "abandoned", "walkover"].includes(m.status as string)
      ) {
        throw new HttpSignal(409, "match_finalised", "Match is already finished");
      }
      const fmt = (m?.format ?? {}) as Record<string, unknown>;

      const prevRows = await tx`
        select ball_type from balls
         where match_id = ${matchId} and innings_number = ${inningsNumber}
           and ball_type <> 'wide'
         order by seq desc limit 1`;
      const prevNonWideKind = (prevRows[0]?.ball_type ?? null) as BallKind | null;

      // Legal balls the current bowler has already bowled this innings — drives
      // the per-bowler over-cap.
      const bowlerRows = await tx`
        select count(*)::int as n from balls
         where match_id = ${matchId} and innings_number = ${inningsNumber}
           and bowler_id = ${s.bowler_id} and is_legal_delivery = true`;
      const bowlerLegalBalls = Number(bowlerRows[0]?.n ?? 0);

      const state: InningsState = {
        strikerId: s.striker_id,
        nonStrikerId: s.non_striker_id,
        bowlerId: s.bowler_id,
        legalBallCount: s.legal_ball_count,
        totalRuns: s.total_runs,
        totalWickets: s.total_wickets,
        totalExtras: s.total_extras,
        isAllOut: s.is_all_out,
        isDeclared: s.is_declared,
        target: s.target,
        version: Number(s.version),
      };
      const format: MatchFormat = {
        oversPerInnings: num(fmt.overs_per_innings, 0),
        playersPerTeam: num(fmt.players_per_team, 11),
        ballsPerOver: num(fmt.balls_per_over, 6),
        maxOversPerBowler: num(fmt.max_overs_per_bowler, 0),
        inningsPerSide: num(fmt.innings_per_side, 1),
        ballType: (fmt.ball_type as MatchFormat["ballType"]) ?? "leather",
        wicketsToAllOut: fmt.wickets_to_all_out != null
          ? Number(fmt.wickets_to_all_out)
          : undefined,
      };
      const input: BallInput = {
        isLegalDelivery: body.p_is_legal_delivery === true,
        ballKind: (body.p_ball_type as BallKind) ?? "legal",
        runsScored: num(body.p_runs_scored, 0),
        extras: num(body.p_extras, 0),
        isWicket: body.p_is_wicket === true,
        wicketType: (body.p_wicket_type as BallInput["wicketType"]) ?? null,
        batsmanId: (body.p_batsman_id as string) ?? null,
        nonStrikerId: (body.p_non_striker_id as string) ?? null,
        bowlerId: (body.p_bowler_id as string) ?? null,
        fielderId: (body.p_fielder_id as string) ?? null,
        commentary: (body.p_commentary as string) ?? null,
      };

      // Compute (pure, authoritative — runs while we hold the row lock).
      const result = applyBall(state, format, input, {
        prevNonWideKind,
        bowlerLegalBalls,
      });
      if (!result.ok) {
        throw new HttpSignal(422, result.error!.code, result.error!.message);
      }
      const b = result.ball!;
      const ns = result.newState!;
      const events = result.events!;

      const inserted = await tx`
        insert into balls (
          match_id, innings_number, over_number, ball_in_over,
          is_legal_delivery, ball_type, runs_scored, extras,
          is_wicket, wicket_type, is_free_hit,
          batsman_id, non_striker_id, bowler_id, fielder_id,
          commentary, created_by
        ) values (
          ${matchId}, ${inningsNumber}, ${b.overNumber}, ${b.ballInOver},
          ${b.isLegalDelivery}, ${b.ballKind}, ${b.runsScored}, ${b.extras},
          ${b.isWicket}, ${b.wicketType}, ${b.isFreeHit},
          ${b.batsmanId}, ${b.nonStrikerId}, ${b.bowlerId}, ${b.fielderId},
          ${b.commentary}, ${actor}
        ) returning *`;

      await tx`
        update match_innings_state set
          legal_ball_count = ${ns.legalBallCount},
          total_runs       = ${ns.totalRuns},
          total_wickets    = ${ns.totalWickets},
          total_extras     = ${ns.totalExtras},
          striker_id       = ${ns.strikerId},
          non_striker_id   = ${ns.nonStrikerId},
          bowler_id        = ${ns.bowlerId},
          is_all_out       = ${events.allOut},
          version          = version + 1
        where match_id = ${matchId} and innings_number = ${inningsNumber}`;

      // ── Innings termination ──
      let transition: {
        kind: "none" | "innings_break" | "completed";
        result?: unknown;
      } = { kind: "none" };

      if (events.inningsEnded) {
        const inningsPerSide = format.inningsPerSide > 0
          ? format.inningsPerSide
          : 1;
        const isFinalInnings = inningsNumber >= inningsPerSide * 2;

        if (!isFinalInnings) {
          await tx`
            update matches set status = 'innings_break'
             where match_id = ${matchId}`;
          transition = { kind: "innings_break" };
        } else {
          // Build per-innings lines (current innings already reflects the new
          // totals because we read within the same transaction).
          const innRows = await tx`
            select innings_number, total_runs, total_wickets, legal_ball_count,
                   is_all_out
              from match_innings_state
             where match_id = ${matchId}
             order by innings_number`;
          const lines = toInningsLines(innRows, m);
          const res = computeResult(lines, format);
          await tx`
            update matches set
              status   = 'completed',
              end_time = now(),
              result   = ${
            tx.json({
              winner_team_id: res.winnerTeamId,
              win_type: res.winType,
              win_margin: res.winMargin,
              // `description` is the key the Flutter MatchDto reads into
              // Match.resultDescription; keep `summary` too as a friendly alias.
              description: res.description,
              summary: res.description,
              innings: lines.map((l) => ({
                team_id: l.battingTeamId,
                runs: l.runs,
                wickets: l.wickets,
                overs: l.legalBalls / (format.ballsPerOver || 6),
              })),
            })
          }
             where match_id = ${matchId}`;
          transition = { kind: "completed", result: res };
        }
      }

      return { ball: inserted[0], events, transition };
    });

    return json(200, {
      ok: true,
      ball: out.ball,
      events: out.events,
      transition: out.transition,
    });
  } catch (e) {
    if (e instanceof ConflictSignal) {
      return json(409, { ok: false, conflict: true });
    }
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

function num(v: unknown, fallback: number): number {
  const n = Number(v);
  return Number.isFinite(n) ? n : fallback;
}

// Map innings_state rows → result InningsLine[], deriving each innings's batting
// team from the toss (odd innings = bats-first team). Mirrors the client's
// _battingTeamId so server and client agree.
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
