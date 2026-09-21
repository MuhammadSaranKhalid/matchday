// Canonical cricket-match-action types.
//
// Multi-sport storage boundary:
//   matches         = sport-neutral sporting-event shell
//   match_teams     = sport-neutral team_a/team_b competitor slots
//   cricket_matches = Cricket-only workflow/rules/result extension
//
// Authorization boundary:
//   - matches.created_by is audit/history only.
//   - cricket_matches.setup_side identifies the side that initially owns
//     Cricket pre-match setup for peer-to-peer fixtures.
//   - public.can(...) is the authorization source of truth.
//   - assigned officials may receive match-scoped Cricket capabilities.

export type Tx = any;

export type Action =
  | "record_toss"
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
  // Generic match shell ------------------------------------------------------
  matchId: string;
  tournamentId: string | null;
  matchType: string;
  sportId: string;
  status: MatchLifecycle;

  // Derived from sport-neutral match_teams. These are conveniences in memory,
  // not columns on public.matches.
  teamAId: string | null;
  teamBId: string | null;
  teamAName: string | null;
  teamBName: string | null;

  createdBy: string | null;
  venue: string | null;
  scheduledStartTime: string | null;
  actualStartTime: string | null;
  completedAt: string | null;
  winnerSide: TeamSide | null;

  // Cricket extension --------------------------------------------------------
  // Null is valid for neutral tournament fixtures whose setup authority comes
  // from a match-scoped cricket.match.setup grant.
  setupSide: TeamSide | null;

  phase: CricketPhase;
  tossWonBy: TeamSide | null;
  tossDecision: TossDecision | null;
  tossFace: string | null;
  tossRecordedAt: string | null;
  tossRecordedBy: string | null;

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
