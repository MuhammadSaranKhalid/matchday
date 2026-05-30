// record-ball — Slice A edge orchestrator (all-TypeScript write path).
//
// Replaces the fat `record_ball` RPC on the scoring hot path. Flow:
//   1. identify the caller (JWT → actor)
//   2. authorize with the EXISTING _can_score_match() rule, run AS the user
//   3. open ONE Postgres transaction over a direct connection:
//        lock the innings row (FOR UPDATE) → read state/format/prev delivery →
//        compute the ball with the pure engine → insert balls + update
//        innings_state → commit
//
// The lock + transaction live here in TypeScript (a direct Postgres connection),
// not in a SQL function — PostgREST/supabase-js has no transactions, so this is
// the only safe all-TS way to write two tables atomically with the version
// guard. The per-table triggers (broadcast_new_ball, _balls_assign_seq,
// broadcast_innings_state, set_updated_at) fire on these writes exactly as they
// did for record_ball, so realtime is unchanged.
//
// Request body is the SAME `p_*` shape the Flutter repo already builds for
// record_ball, so only the transport changed on the client. Responses:
//   200 { ok:true, ball }            — written
//   422 { ok:false, error }          — engine rejected the delivery
//   409 { ok:false, conflict:true }  — version moved (another scorer); retry
//   401/403 { ok:false, error }      — not signed in / not allowed to score
//
// verify_jwt stays at its default (true): the gateway rejects anonymous calls,
// and the Flutter client attaches the user's access token automatically.

import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { db, userClient } from "../_shared/db.ts";
import { json } from "../_shared/http.ts";
import { applyBall } from "../_shared/scoring/engine.ts";
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

  // 3. Authorize via the existing server-side rule, run AS the user. This is a
  //    read (not a write) and reuses _can_score_match's organiser / scorer /
  //    friendly-creator branches with the caller's real identity.
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

  // 4. One atomic transaction: lock → read → compute → write.
  try {
    const ballRow = await sql.begin(async (tx) => {
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

      // Double-commit guard: the version the client computed against must still
      // be current. Null (single-scorer flows) relies on the FOR UPDATE lock.
      if (expectedVersion !== null && Number(s.version) !== expectedVersion) {
        throw new ConflictSignal();
      }

      const matchRows = await tx`
        select format from matches where match_id = ${matchId}`;
      const fmt = (matchRows[0]?.format ?? {}) as Record<string, unknown>;

      const prevRows = await tx`
        select ball_type from balls
         where match_id = ${matchId} and innings_number = ${inningsNumber}
           and ball_type <> 'wide'
         order by seq desc limit 1`;
      const prevNonWideKind = (prevRows[0]?.ball_type ?? null) as BallKind | null;

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
      const result = applyBall(state, format, input, { prevNonWideKind });
      if (!result.ok) {
        throw new HttpSignal(422, result.error!.code, result.error!.message);
      }
      const b = result.ball!;
      const ns = result.newState!;

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
          version          = version + 1
        where match_id = ${matchId} and innings_number = ${inningsNumber}`;

      return inserted[0];
    });

    return json(200, { ok: true, ball: ballRow });
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
