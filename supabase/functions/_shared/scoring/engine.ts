// The match scoring engine — the "brains".
//
// applyBall() is a PURE function: given the current innings state, the format,
// the raw delivery, and minimal context, it returns the computed `balls` row,
// the new `match_innings_state`, and a set of events. No I/O.
//
// ── SLICE A (this file) is a VERBATIM port of the deployed `record_ball`
//    plpgsql (migration 20260529144952), reproduced in MATCH_ENGINE_DESIGN.md
//    Appendix A. It deliberately preserves today's behaviour EXACTLY — including
//    quirks like "running on a wide does not change strike" — so the cutover is
//    provably behaviour-neutral. Rule corrections and termination land in Slice B.

import type {
  BallInput,
  BallResult,
  EngineContext,
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
  const newStriker = input.isWicket
    ? null
    : swap
    ? state.nonStrikerId
    : state.strikerId;
  const newNonStriker = swap && !input.isWicket
    ? state.strikerId
    : state.nonStrikerId;
  const newBowler = overEnded ? null : state.bowlerId;

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
      totalRuns: state.totalRuns + runs + extras,
      totalWickets: state.totalWickets + (input.isWicket ? 1 : 0),
      totalExtras: state.totalExtras + extras,
      strikerId: newStriker,
      nonStrikerId: newNonStriker,
      bowlerId: newBowler,
    },
    // Slice A reports over-end (needed for the bowler prompt) but never
    // terminates the innings — that is Slice B.
    events: { overEnded, allOut: false, inningsEnded: false },
  };
}

function err(code: string, message: string): BallResult {
  return { ok: false, error: { code, message } };
}
