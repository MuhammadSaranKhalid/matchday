// Canonical cricket-match-action types.
//
// Physical storage:
//   matches                    = generic event shell
//   match_teams                = canonical team_a/team_b slots
//   cricket_matches            = Cricket state
//
// API projections may still expose team_a_id/team_b_id, but the Edge command
// layer always loads those UUIDs from match_teams.

export type Tx = any;

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

  // Derived from match_teams. These are conveniences in memory, not columns on
  // public.matches.
  teamAId: string | null;
  teamBId: string | null;
  teamAName: string | null;
  teamBName: string | null;

  createdBy: string | null;
  venue: string | null;
  scheduledStartTime: string | null;
  actualStartTime: string | null;
  completedAt: string | null;

  // Canonical generic result identity.
  winnerSide: TeamSide | null;

  phase: CricketPhase;

  // Canonical Cricket toss identity is a side, never a team UUID.
  tossWonBy: TeamSide | null;
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
  result?: unknown;
  inningsNumber?: number;
  ballsResync?: boolean;
}

export interface TransactionOutput {
  result: unknown;
  match: unknown;
  innings: unknown;
  inningsNumber: number | null;
  ballsResync: boolean;
}
