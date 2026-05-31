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

  // ── Over / ball position, derived from the count BEFORE this ball ──
  const overNumber = Math.floor(state.legalBallCount / ballsPerOver);
  const ballInOver = isLegal ? (state.legalBallCount % ballsPerOver) + 1 : 0;

  // ── Free hit: true iff the most recent non-wide delivery was a no-ball ──
  const isFreeHit = ctx.prevNonWideKind === "no_ball";

  // ── Strike rotation (record_ball parity) ──
  // swap when an odd number of runs was run, XOR an odd number of bye/leg-bye
  // runs on a legal delivery; then toggle once more if the over just ended.
  let swap = (runs % 2 === 1) !== (isLegal && extras % 2 === 1);
  const overEnded = isLegal && (state.legalBallCount + 1) % ballsPerOver === 0;
  if (overEnded) swap = !swap;

  const newLegal = state.legalBallCount + (isLegal ? 1 : 0);
  const newTotalRuns = state.totalRuns + runs + extras;
  const newTotalWickets = state.totalWickets + (input.isWicket ? 1 : 0);
  const newStriker = input.isWicket
    ? null
    : swap
    ? state.nonStrikerId
    : state.strikerId;
  const newNonStriker = swap && !input.isWicket
    ? state.strikerId
    : state.nonStrikerId;
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
