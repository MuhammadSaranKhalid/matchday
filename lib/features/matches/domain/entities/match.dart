import 'package:equatable/equatable.dart';

import '../../../teams/domain/entities/team.dart';

/// A match between two teams.
///
/// In the setup flow (F4) a match is created in [MatchStatus.pending] with only
/// team A's side filled in; team B's squad/captain and the status transition are
/// the opponent's job (F5).
class Match extends Equatable {
  const Match({
    required this.id,
    required this.teamAId,
    required this.teamBId,
    required this.format,
    required this.status,
    this.matchType = MatchType.friendly,
    required this.createdBy,
    required this.createdAt,
    this.teamACaptain,
    this.teamBCaptain,
    this.setupTeamId,
    this.venue,
    this.scheduledStartTime,
    this.actualStartTime,
    this.resultDescription,
    this.tossWonBy,
    this.tossDecision,
    this.tossFace,
    this.tossRecordedBy,
    this.startPhase = MatchStartPhase.toss,
    this.openersSubmittedBy,
    this.openersSubmittedAt,
    this.tournamentId,
    this.round,
    this.bracketRoundNumber,
    this.bracketMatchNumber,
    this.prevMatchAId,
    this.prevMatchBId,
  });

  final MatchId id;
  final TeamId teamAId;
  final TeamId teamBId;
  final MatchFormat format;
  final MatchStatus status;

  /// Tournament / friendly / practice. Drives the label in the scoring top
  /// bar and, later, which rules apply.
  final MatchType matchType;

  final String createdBy;
  final DateTime createdAt;

  /// Captain snapshot used for display/relationship context.
  ///
  /// IMPORTANT: captain identity does not authorize Match Start. Effective
  /// authorization is resolved by the generic RBAC permission matrix.
  final String? teamACaptain;
  final String? teamBCaptain;

  /// Team currently occupying `cricket_matches.setup_side`, projected through
  /// `cricket_match_details`. This is Cricket workflow state, not a column on
  /// the sport-neutral `matches` shell.
  ///
  /// It is NOT the same thing as createdBy.
  final TeamId? setupTeamId;

  final Venue? venue;
  final DateTime? scheduledStartTime;
  final DateTime? actualStartTime;

  /// Human-readable outcome once the match is completed (e.g. the final score).
  final String? resultDescription;

  // Tournament metadata
  final String? tournamentId;
  final String? round;
  final int? bracketRoundNumber;
  final int? bracketMatchNumber;
  final String? prevMatchAId;
  final String? prevMatchBId;

  // ── Match-start state (mirrors deployed `matches` row) ─────────────────────

  /// Team that won the toss (null until the host phone records it).
  final TeamId? tossWonBy;

  /// Bat / bowl decision by the toss winner.
  final TossDecision? tossDecision;

  /// Coin face the host phone observed. Cosmetic — used by the result banner.
  final String? tossFace;

  /// User who entered the complete physical toss result.
  final String? tossRecordedBy;

  /// Where the match is in the pre-live → live progression.
  final MatchStartPhase startPhase;

  /// User_id of the person who most recently locked the openers. Useful
  /// for audit/display only; any caller with effective match setup capability
  /// may perform the server-authorized setup operation.
  /// The actual opener match_player_ids live on `match_innings_state` —
  /// see `MatchInningsState.strikerId` / `nonStrikerId`.
  final String? openersSubmittedBy;
  final DateTime? openersSubmittedAt;

  // NOTE: the playing XI, the keeper, the live on-field trio
  // (striker / non-striker / bowler), and the active innings number no
  // longer live on this row. They moved to:
  //
  //   * `MatchPlayer`        (lib/.../entities/match_player.dart) —
  //                          the per-match XI with profile/unclaimed XOR.
  //                          Keeper is a flag on each row.
  //   * `MatchInningsState`  (lib/.../entities/match_innings_state.dart)
  //                          — on-field trio + denormalised totals +
  //                          version counter, per (match, innings_number).
  //
  // Callers that previously read `match.teamASquad` / `match.currentStrikerId`
  // / `match.currentInnings` etc. should watch `matchPlayersProvider` and
  // `liveInningsStateProvider` respectively.

  /// True when this match is in a state where participants are expected to
  /// act or observe — open, in-play, or recently concluded. Delegates to
  /// [MatchStatus.isActive].
  bool get isActive => status.isActive;

  Match copyWith({
    MatchId? id,
    TeamId? teamAId,
    TeamId? teamBId,
    MatchFormat? format,
    MatchStatus? status,
    MatchType? matchType,
    String? createdBy,
    DateTime? createdAt,
    String? teamACaptain,
    String? teamBCaptain,
    TeamId? setupTeamId,
    Venue? venue,
    DateTime? scheduledStartTime,
    DateTime? actualStartTime,
    String? resultDescription,
    TeamId? tossWonBy,
    TossDecision? tossDecision,
    String? tossFace,
    String? tossRecordedBy,
    MatchStartPhase? startPhase,
    String? openersSubmittedBy,
    DateTime? openersSubmittedAt,
  }) => Match(
    id: id ?? this.id,
    teamAId: teamAId ?? this.teamAId,
    teamBId: teamBId ?? this.teamBId,
    format: format ?? this.format,
    status: status ?? this.status,
    matchType: matchType ?? this.matchType,
    createdBy: createdBy ?? this.createdBy,
    createdAt: createdAt ?? this.createdAt,
    teamACaptain: teamACaptain ?? this.teamACaptain,
    teamBCaptain: teamBCaptain ?? this.teamBCaptain,
    setupTeamId: setupTeamId ?? this.setupTeamId,
    venue: venue ?? this.venue,
    scheduledStartTime: scheduledStartTime ?? this.scheduledStartTime,
    actualStartTime: actualStartTime ?? this.actualStartTime,
    resultDescription: resultDescription ?? this.resultDescription,
    tossWonBy: tossWonBy ?? this.tossWonBy,
    tossDecision: tossDecision ?? this.tossDecision,
    tossFace: tossFace ?? this.tossFace,
    tossRecordedBy: tossRecordedBy ?? this.tossRecordedBy,
    startPhase: startPhase ?? this.startPhase,
    openersSubmittedBy: openersSubmittedBy ?? this.openersSubmittedBy,
    openersSubmittedAt: openersSubmittedAt ?? this.openersSubmittedAt,
  );

  @override
  List<Object?> get props => [
    id,
    teamAId,
    teamBId,
    setupTeamId,
    status,
    scheduledStartTime,
    tossWonBy,
    tossDecision,
    startPhase,
  ];
}

/// Cricket Match Start workflow helpers.
///
/// These helpers answer DOMAIN questions only:
///
/// - Who bats first?
/// - Which team currently controls Cricket setup?
/// - Is this match still in the pre-live setup workflow?
///
/// They deliberately do NOT answer:
///
/// "May the current user perform the action?"
///
/// User authorization belongs to the RBAC engine (`can` / `team_can`).
/// Keeping these concerns separate prevents role names or UI state from
/// becoming accidental authorization logic.
extension CricketMatchSetupX on Match {
  /// The team that bats in innings 1 according to the committed toss.
  ///
  /// Before the toss is recorded there is no batting team yet.
  TeamId? get battingFirstTeamId {
    final winner = tossWonBy;
    final decision = tossDecision;

    if (winner == null || decision == null) {
      return null;
    }

    // Toss winner chose to bat, so they bat first.
    if (decision == TossDecision.bat) {
      return winner;
    }

    // Toss winner chose to bowl, therefore the OTHER team bats first.
    if (winner == teamAId) {
      return teamBId;
    }

    if (winner == teamBId) {
      return teamAId;
    }

    // Defensive fail-closed branch. A valid toss winner should always be one
    // of the two participating teams.
    return null;
  }

  /// Team whose TEAM-SCOPED `cricket.match.setup` permission controls the
  /// current Match Start stage.
  ///
  /// Match-scoped grants are deliberately NOT represented here because they
  /// are independent of either team and are checked separately by RBAC.
  TeamId? get currentSetupAuthorityTeamId {
    switch (startPhase) {
      case MatchStartPhase.toss:
        // Before the toss, authority comes from cricket_matches.setup_side.
        return setupTeamId;
      case MatchStartPhase.lineup:
      case MatchStartPhase.ready:
        // Once the toss is committed, authority transfers to the batting side.
        return battingFirstTeamId;
      case MatchStartPhase.live:
        // Match Start has finished. Scoring uses match.score instead.
        return null;
    }
  }

  /// Whether this fixture is still in the Match Start workflow.
  ///
  /// There is intentionally NO time rule here.
  ///
  /// A future product rule such as "only 30 minutes before start" must be
  /// introduced separately. Time does not currently determine authorization.
  bool get isPreLiveCricketSetup =>
      status.isUpcoming && startPhase != MatchStartPhase.live;
}

class MatchId extends Equatable {
  const MatchId(this.value);
  final String value;
  @override
  List<Object?> get props => [value];
  @override
  String toString() => value;
}

/// Match format — the rule knobs the scoring engine enforces. See
/// CRICKET_FORMATS.md for how each format maps onto these fields.
class MatchFormat extends Equatable {
  const MatchFormat({
    required this.oversPerInnings,
    required this.playersPerTeam,
    required this.ballType,
    required this.maxOversPerBowler,
    this.ballsPerOver = 6,
    this.inningsPerSide = 1,
    this.wicketsToAllOut,
    this.endChangeBalls,
  });

  final int oversPerInnings; // 0 = unlimited (Test / first-class)
  final int playersPerTeam;
  final MatchBallType ballType;
  final int maxOversPerBowler; // 0 = unlimited

  /// 6 standard; 5 (The Hundred / LMS); 8 (indoor).
  final int ballsPerOver;

  /// 1 limited-overs; 2 Test / first-class.
  final int inningsPerSide;

  /// Wickets that end the innings. Null → derived as playersPerTeam - 1.
  final int? wicketsToAllOut;

  /// Balls between end changes (strike swaps). Null → ballsPerOver; The
  /// Hundred uses 10.
  final int? endChangeBalls;

  @override
  List<Object?> get props => [
    oversPerInnings,
    playersPerTeam,
    ballType,
    maxOversPerBowler,
    ballsPerOver,
    inningsPerSide,
    wicketsToAllOut,
    endChangeBalls,
  ];
}

class Venue extends Equatable {
  const Venue({required this.ground, this.city});
  final String ground;
  final String? city;

  @override
  List<Object?> get props => [ground, city];
}

enum MatchBallType {
  leather('leather'),
  tape('tape'),
  tennis('tennis');

  const MatchBallType(this.wire);
  final String wire;
  static MatchBallType fromWire(String? w) =>
      values.where((b) => b.wire == w).firstOrNull ?? MatchBallType.tape;
}

enum TossDecision {
  bat('bat'),
  bowl('bowl');

  const TossDecision(this.wire);
  final String wire;
  static TossDecision fromWire(String? w) =>
      values.where((d) => d.wire == w).firstOrNull ?? TossDecision.bat;
}

/// Mirrors the deployed `match_start_phase` enum. Drives which of the three
/// Match Start stages renders. After `live`, the scoring screen takes over.
enum MatchStartPhase {
  toss('toss'),
  lineup('lineup'),
  ready('ready'),
  live('live');

  const MatchStartPhase(this.wire);
  final String wire;
  static MatchStartPhase fromWire(String? w) =>
      values.where((s) => s.wire == w).firstOrNull ?? MatchStartPhase.toss;
}

/// Mirrors the deployed `match_type` enum.
enum MatchType {
  tournament('tournament', 'TOURNAMENT'),
  friendly('friendly', 'FRIENDLY'),
  practice('practice', 'PRACTICE');

  const MatchType(this.wire, this.label);
  final String wire;

  /// Uppercase display form, as used by the scoring top bar.
  final String label;

  static MatchType fromWire(String? w) =>
      values.where((t) => t.wire == w).firstOrNull ?? MatchType.friendly;
}

enum MatchStatus {
  // Legacy values (pre-match-requests). Unreachable in the new flow — the
  // deployed `match_status` enum does NOT include these — but kept so older
  // rows or hand-typed strings don't crash fromWire.
  pending('pending'),
  accepted('accepted'),
  declined('declined'),
  cancelled('cancelled'),

  // `match_status` enum values, in order. Kept in step with the definition in
  // supabase/migrations/20260101000000_shared_helpers.sql.
  //
  // `tied` and `no_result` were missing here while the SQL enum had them, and
  // `rescheduled` was here while the SQL enum did not — the two halves of the
  // same drift, reconciled 2026-09-06. Their absence mattered: fromWire falls
  // back to `scheduled`, so a completed tied match rendered as upcoming.
  scheduled('scheduled'),
  toss('toss'),
  rescheduled('rescheduled'),
  live('live'),
  inningsBreak('innings_break'),
  superOver('super_over'),
  completed('completed'),
  abandoned('abandoned'),
  tied('tied'),
  noResult('no_result'),
  walkover('walkover');

  const MatchStatus(this.wire);
  final String wire;
  static MatchStatus fromWire(String? w) =>
      values.where((s) => s.wire == w).firstOrNull ?? MatchStatus.scheduled;

  /// Confirmed-upcoming: cards in this state belong in the "Confirmed" tab on
  /// My Matches.
  bool get isUpcoming =>
      this == scheduled || this == toss || this == rescheduled;

  /// In-play.
  bool get isLive => this == live || this == inningsBreak || this == superOver;

  /// Past — match has a final result (or terminal non-result).
  bool get isPast =>
      this == completed ||
      this == abandoned ||
      this == walkover ||
      this == tied ||
      this == noResult;

  /// True for statuses that represent a match worth participants' attention —
  /// upcoming, in-play, or recently concluded. Legacy [pending] / [accepted]
  /// are also active so the pre-match-requests teams hero card keeps working
  /// against any rows still carrying those statuses.
  bool get isActive =>
      isUpcoming ||
      isLive ||
      this == completed ||
      this == pending ||
      this == accepted;
}
