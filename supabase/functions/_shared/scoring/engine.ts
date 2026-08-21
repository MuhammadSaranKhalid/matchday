// The match scoring engine — the "brains".
//
// applyBall() is a PURE function: given the current innings state, the format,
// the raw delivery, and minimal context, it returns the computed `balls` row,
// the new `match_innings_state`, and a set of events. No I/O.
//
// The per-ball maths is a behaviour-preserving port of the deployed `record_ball`
// plpgsql (MATCH_ENGINE_DESIGN.md Appendix A). On top of that it now computes
// INNINGS TERMINATION (Slice B / F1): all-out, overs complete, target reached,
// or declared. The engine only REPORTS these via `events` — the edge
// orchestrator decides what to do (start the next innings or complete the match).

import type {
  BallInput,
  BallResult,
  EngineContext,
  InningsEndReason,
  InningsState,
  MatchFormat,
} from "./types.ts";

export function applyBall(
  state: InningsState,
  format: MatchFormat,
  input: BallInput,
  ctx: EngineContext,
): BallResult {
  const ballsPerOver = format.ballsPerOver > 0 ? format.ballsPerOver : 6;
  const runs = input.runsScored ?? 0;
  const extras = input.extras ?? 0;
  const isLegal = input.isLegalDelivery;

  // ── Validation (mirrors record_ball's guards) ──
  if (input.isWicket && input.wicketType == null) {
    return err("wicket_type_required", "A wicket needs a wicket type");
  }
  if (!input.isWicket && input.wicketType != null) {
    return err(
      "wicket_type_unexpected",
      "wicket_type must be null when this delivery is not a wicket",
    );
  }
  if (runs < 0 || extras < 0) {
    return err("negative_runs", "Runs and extras must be non-negative");
  }

  // ── Wide attribution: nothing off a wide is ever credited to the batter.
  //    Under the Laws a wide is a penalty to the bowling side, and any runs
  //    the batters then run are extras too — so `runsScored` must be 0 and
  //    the whole lot (penalty + runs run) belongs in `extras`.
  //
  //    This is a real client bug the engine used to accept: the scoring
  //    screen sent a wide's runs as `runsScored`, which kept the TEAM total
  //    right but inflated the batter's individual score and understated the
  //    extras column. The scoreboard looked fine; the scorecard was wrong.
  //    Guarding here because the engine is the last line of defence, and
  //    because the Laws make this unambiguous. ──
  if (input.ballKind === "wide" && runs > 0) {
    return err(
      "wide_runs_to_batter",
      "Runs off a wide are extras — send them in `extras`, not `runsScored`",
    );
  }
  if (input.ballKind === "wide" && extras < 1) {
    return err(
      "wide_missing_penalty",
      "A wide must carry at least the 1-run penalty in `extras`",
    );
  }

  // ── Bowler over-cap (B1): a bowler may bowl at most maxOversPerBowler overs
  //    = maxOversPerBowler * ballsPerOver legal balls. 0 = no cap. ──
  if (
    isLegal &&
    format.maxOversPerBowler > 0 &&
    (ctx.bowlerLegalBalls ?? 0) >= format.maxOversPerBowler * ballsPerOver
  ) {
    return err(
      "bowler_over_cap",
      `Bowler has reached the ${format.maxOversPerBowler}-over limit`,
    );
  }

  // ── Over / ball position, derived from the count BEFORE this ball ──
  const overNumber = Math.floor(state.legalBallCount / ballsPerOver);
  const ballInOver = isLegal ? (state.legalBallCount % ballsPerOver) + 1 : 0;

  // ── Free hit: true iff the most recent non-wide delivery was a no-ball ──
  const isFreeHit = ctx.prevNonWideKind === "no_ball";

  // ── Free-hit dismissals (B5): on a free hit only run out / hit wicket /
  //    obstructing / handled ball can dismiss the striker (mirrors the DB
  //    balls_free_hit_dismissal_check constraint). ──
  if (isFreeHit && input.isWicket) {
    const allowed = ["run_out", "hit_wicket", "obstructing", "handled_ball"];
    if (input.wicketType == null || !allowed.includes(input.wicketType)) {
      return err(
        "free_hit_dismissal",
        "On a free hit the batter can only be run out, hit wicket, " +
          "obstructing, or handled ball",
      );
    }
  }

  // ── Strike rotation ──
  // The batters change ends when they physically RUN an odd number of runs.
  // That is every run except the automatic penalty on a wide or no-ball,
  // which is awarded, not run:
  //
  //   legal      ran = runsScored (off the bat) + extras (byes / leg-byes)
  //   wide       ran = extras - 1        (the 1 is the wide penalty)
  //   no-ball    ran = runsScored + extras - 1   (the 1 is the nb penalty)
  //
  // Boundaries fall out for free: 4 and 6 are even, so no swap.
  //
  // This replaces `(runs % 2) !== (isLegal && extras % 2)`, which only gave
  // the right answer while the client mis-filed a wide's runs as `runsScored`.
  // With the attribution corrected above, that old rule would have silently
  // stopped rotating strike on a wide — so the guard and this had to land
  // together.
  const penalty = input.ballKind === "wide" || input.ballKind === "no_ball"
    ? 1
    : 0;
  const runsRun = runs + extras - penalty;

  const endChangeBalls = format.endChangeBalls && format.endChangeBalls > 0
    ? format.endChangeBalls
    : ballsPerOver;
  let swap = runsRun % 2 === 1;
  // A "set"/over boundary (a new bowler may come on) is every ballsPerOver. The
  // ENDS change (strike swaps) every endChangeBalls — equal to ballsPerOver for
  // normal cricket, but 10 for The Hundred (two 5-ball sets per end).
  const overEnded = isLegal && (state.legalBallCount + 1) % ballsPerOver === 0;
  const endChanged = isLegal &&
    (state.legalBallCount + 1) % endChangeBalls === 0;
  if (endChanged) swap = !swap;

  const newLegal = state.legalBallCount + (isLegal ? 1 : 0);
  const newTotalRuns = state.totalRuns + runs + extras;
  const newTotalWickets = state.totalWickets + (input.isWicket ? 1 : 0);

  const endAOccupant = swap ? state.nonStrikerId : state.strikerId;
  const endBOccupant = swap ? state.strikerId : state.nonStrikerId;

  const isNonStrikerOut = input.isWicket &&
    input.dismissedPlayerId != null &&
    input.dismissedPlayerId === state.nonStrikerId;
  const dismissed = input.isWicket
    ? (isNonStrikerOut ? state.nonStrikerId : state.strikerId)
    : null;

  const newStriker = input.isWicket
    ? (endAOccupant === dismissed ? null : endAOccupant)
    : endAOccupant;
  const newNonStriker = input.isWicket
    ? (endBOccupant === dismissed ? null : endBOccupant)
    : endBOccupant;
  const newBowler = overEnded ? null : state.bowlerId;

  // ── Innings termination ──
  // wicketsToAllOut defaults to (playersPerTeam - 1); a format can override it
  // (e.g. non-XI sizes). Bespoke models that never go "all out" (indoor pairs)
  // will set it to 0, which disables the all-out check.
  const wicketsToAllOut = format.wicketsToAllOut ?? (format.playersPerTeam - 1);
  const allOut = wicketsToAllOut > 0 && newTotalWickets >= wicketsToAllOut;
  const oversComplete = format.oversPerInnings > 0 &&
    newLegal >= format.oversPerInnings * ballsPerOver;
  const targetReached = state.target != null && newTotalRuns >= state.target;
  const inningsEnded = allOut || oversComplete || targetReached ||
    state.isDeclared;
  // Precedence for the primary reason: a chase won (target) beats all-out beats
  // overs-exhausted beats a standing declaration.
  const inningsEndReason: InningsEndReason | null = targetReached
    ? "target"
    : allOut
    ? "all_out"
    : oversComplete
    ? "overs"
    : state.isDeclared
    ? "declared"
    : null;

  return {
    ok: true,
    ball: {
      overNumber,
      ballInOver,
      isFreeHit,
      isLegalDelivery: isLegal,
      ballKind: input.ballKind,
      runsScored: runs,
      extras,
      isWicket: input.isWicket,
      wicketType: input.wicketType,
      dismissedPlayerId: input.dismissedPlayerId ?? (input.isWicket ? (isNonStrikerOut ? state.nonStrikerId : state.strikerId) : null),
      batsmanId: input.batsmanId,
      nonStrikerId: input.nonStrikerId,
      bowlerId: input.bowlerId,
      fielderId: input.fielderId,
      commentary: input.commentary,
    },
    newState: {
      legalBallCount: newLegal,
      totalRuns: newTotalRuns,
      totalWickets: newTotalWickets,
      totalExtras: state.totalExtras + extras,
      strikerId: newStriker,
      nonStrikerId: newNonStriker,
      bowlerId: newBowler,
    },
    events: {
      overEnded,
      allOut,
      oversComplete,
      targetReached,
      inningsEnded,
      inningsEndReason,
    },
  };
}

function err(code: string, message: string): BallResult {
  return { ok: false, error: { code, message } };
}
