// Shared types for the match scoring engine.
//
// The engine is PURE — these types describe data in / data out and carry no
// I/O, no DB, no Supabase. The edge function (the DB adapter) maps these
// camelCase shapes to/from the snake_case `balls` / `match_innings_state`
// columns. See MATCH_ENGINE_DESIGN.md.

/** Mirrors the deployed `ball_kind` enum (the delivery kind). */
export type BallKind = "legal" | "wide" | "no_ball" | "bye" | "leg_bye";

/** Mirrors the deployed `wicket_kind` enum (all 10 dismissal types). */
export type WicketKind =
  | "bowled"
  | "caught"
  | "lbw"
  | "run_out"
  | "stumped"
  | "hit_wicket"
  | "retired_hurt"
  | "obstructing"
  | "timed_out"
  | "handled_ball";

/** The current, authoritative state of one innings (as read from
 * `match_innings_state`). */
export interface InningsState {
  strikerId: string | null;
  nonStrikerId: string | null;
  bowlerId: string | null;
  legalBallCount: number;
  totalRuns: number;
  totalWickets: number;
  totalExtras: number;
  isAllOut: boolean;
  isDeclared: boolean;
  target: number | null;
  version: number;
}

/** The match format (parsed from `matches.format` jsonb). The engine reads
 * every knob here to enforce the rules of any format. */
export interface MatchFormat {
  oversPerInnings: number; // 0 = unlimited (Test / first-class)
  playersPerTeam: number;
  ballsPerOver: number; // 6 standard; 5 (The Hundred / LMS); 8 (indoor)
  /** Balls between END changes (strike swaps). Defaults to ballsPerOver; The
   * Hundred uses 10 — ends change every two 5-ball sets. */
  endChangeBalls?: number;
  maxOversPerBowler: number; // 0 = unlimited
  inningsPerSide: number; // 1 limited-overs; 2 Test / first-class
  ballType: "leather" | "tape" | "tennis";
  /** Wickets that end the innings. Defaults to `playersPerTeam - 1` when unset;
   * 0 disables the all-out check (bespoke models like indoor pairs). */
  wicketsToAllOut?: number;
}

/** The raw delivery the scorer recorded. */
export interface BallInput {
  isLegalDelivery: boolean;
  ballKind: BallKind;
  runsScored: number;
  extras: number;
  isWicket: boolean;
  wicketType: WicketKind | null;
  batsmanId: string | null;
  nonStrikerId: string | null;
  bowlerId: string | null;
  fielderId: string | null;
  commentary: string | null;
}

export interface EngineContext {
  /** `ball_type` of the most recent NON-wide delivery in this innings, or
   * null for the first delivery. Drives free-hit derivation. */
  prevNonWideKind: BallKind | null;

  /** Legal balls the CURRENT bowler (state.bowlerId) has already bowled in this
   * innings, BEFORE this delivery. Drives the per-bowler over-cap. Defaults to
   * 0 when omitted. */
  bowlerLegalBalls?: number;
}

/** The fully-computed `balls` row to insert (camelCase). */
export interface ComputedBall {
  overNumber: number;
  ballInOver: number;
  isFreeHit: boolean;
  isLegalDelivery: boolean;
  ballKind: BallKind;
  runsScored: number;
  extras: number;
  isWicket: boolean;
  wicketType: WicketKind | null;
  batsmanId: string | null;
  nonStrikerId: string | null;
  bowlerId: string | null;
  fielderId: string | null;
  commentary: string | null;
}

/** The new `match_innings_state` values to write (camelCase). */
export interface NewInningsState {
  legalBallCount: number;
  totalRuns: number;
  totalWickets: number;
  totalExtras: number;
  strikerId: string | null;
  nonStrikerId: string | null;
  bowlerId: string | null;
}

/** Why an innings ended (the primary reason; see engine precedence). */
export type InningsEndReason = "all_out" | "overs" | "target" | "declared";

export interface InningsEvents {
  overEnded: boolean;
  allOut: boolean;
  oversComplete: boolean;
  targetReached: boolean;
  inningsEnded: boolean;
  inningsEndReason: InningsEndReason | null;
}

export interface BallResult {
  ok: boolean;
  error?: { code: string; message: string };
  ball?: ComputedBall;
  newState?: NewInningsState;
  events?: InningsEvents;
}
