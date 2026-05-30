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

/** The match format (parsed from `matches.format` jsonb). Slice A only reads
 * `ballsPerOver` (always 6 today); the rest are carried so Slice B/C can
 * enforce limits without changing this contract. */
export interface MatchFormat {
  oversPerInnings: number; // 0 = unlimited (Slice B/C); Slice A does not enforce
  playersPerTeam: number;
  ballsPerOver: number; // Slice A: 6
  maxOversPerBowler: number; // 0 = unlimited
  inningsPerSide: number; // Slice A/B: 1
  ballType: "leather" | "tape" | "tennis";
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

export interface InningsEvents {
  overEnded: boolean;
  allOut: boolean; // Slice A: always false; activated in Slice B
  inningsEnded: boolean; // Slice A: always false; activated in Slice B
}

export interface BallResult {
  ok: boolean;
  error?: { code: string; message: string };
  ball?: ComputedBall;
  newState?: NewInningsState;
  events?: InningsEvents;
}
