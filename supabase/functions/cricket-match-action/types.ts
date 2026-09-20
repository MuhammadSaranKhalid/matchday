// Shared types for the cricket-match-action command boundary.
//
// The Edge Function owns Cricket workflow/business behavior.
// PostgreSQL owns durable integrity: FKs, CHECKs, UNIQUE constraints, RLS/grants,
// immutable parent-child relationships and stable generic authorization helpers.

export type Tx = any; // postgres.js TransactionSql; kept local to avoid runtime type coupling.

export type Action =
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

export type TeamSide = "team_a" | "team_b";
export type TossDecision = "bat" | "bowl";
export type MatchLifecycle =
  | "scheduled"
  | "live"
  | "completed"
  | "abandoned"
  | "cancelled";

export type CricketPhase =
  | "toss"
  | "lineup"
  | "ready"
  | "live"
  | "innings_break"
  | "super_over"
  | "complete";

export interface MatchBundle {
  matchId: string;
  tournamentId: string | null;
  matchType: string;
  sportId: string;
  status: MatchLifecycle;
  teamAId: string | null;
  teamBId: string | null;
  createdBy: string | null;
  venue: string | null;
  scheduledStartTime: string | null;
  actualStartTime: string | null;
  completedAt: string | null;
  winnerId: string | null;

  phase: CricketPhase;
  tossWonBy: string | null;
  tossDecision: TossDecision | null;
  tossFace: string | null;
  tossRecordedAt: string | null;
  rulesSnapshot: Record<string, unknown>;
  revisedConditions: Record<string, unknown> | null;
  result: Record<string, unknown> | null;
}

export interface RequestEnvelope {
  action: Action;
  matchId: string;
  body: Record<string, unknown>;
}

export interface CommandContext {
  tx: Tx;
  actorId: string;
  matchId: string;
  body: Record<string, unknown>;
}

export interface CommandResult {
  // Returned as response.data.result. Most commands do not need one.
  result?: unknown;

  // When set, index.ts fetches the canonical innings snapshot inside the same
  // transaction and publishes it after commit.
  inningsNumber?: number;

  // Undo changes the delivery ledger. The client should re-hydrate balls from
  // the database instead of trying to reverse a possibly stale local list.
  ballsResync?: boolean;
}

export interface TransactionOutput {
  result: unknown;
  match: unknown;
  innings: unknown;
  inningsNumber: number | null;
  ballsResync: boolean;
}
