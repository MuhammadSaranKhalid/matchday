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
    this.venue,
    this.scheduledStartTime,
    this.actualStartTime,
    this.resultDescription,
    this.tossWonBy,
    this.tossDecision,
    this.tossFace,
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

  /// Permanent captain pinned on the matches row. Drives the toss-time
  /// auth check (`_is_match_captain`) before any match_players rows
  /// exist. The per-match captain flag for a single fixture lives on
  /// `MatchPlayer.isCaptain`.
  final String? teamACaptain;
  final String? teamBCaptain;
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

  /// Where the match is in the pre-live → live progression.
  final MatchStartPhase startPhase;

  /// User_id of the captain who locked the openers. Drives the "Locked by
  /// Imran" caption + the EDIT PICKS affordance (only the locker can edit).
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
    Venue? venue,
    DateTime? scheduledStartTime,
    DateTime? actualStartTime,
    String? resultDescription,
    TeamId? tossWonBy,
    TossDecision? tossDecision,
    String? tossFace,
    MatchStartPhase? startPhase,
    String? openersSubmittedBy,
    DateTime? openersSubmittedAt,
  }) =>
      Match(
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
        venue: venue ?? this.venue,
        scheduledStartTime: scheduledStartTime ?? this.scheduledStartTime,
        actualStartTime: actualStartTime ?? this.actualStartTime,
        resultDescription: resultDescription ?? this.resultDescription,
        tossWonBy: tossWonBy ?? this.tossWonBy,
        tossDecision: tossDecision ?? this.tossDecision,
        tossFace: tossFace ?? this.tossFace,
        startPhase: startPhase ?? this.startPhase,
        openersSubmittedBy: openersSubmittedBy ?? this.openersSubmittedBy,
        openersSubmittedAt: openersSubmittedAt ?? this.openersSubmittedAt,
      );

  @override
  List<Object?> get props => [
        id,
        teamAId,
        teamBId,
        status,
        scheduledStartTime,
        tossWonBy,
        tossDecision,
        startPhase,
      ];
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

  // Deployed `match_status` enum values, in order.
  scheduled('scheduled'),
  toss('toss'),
  live('live'),
  inningsBreak('innings_break'),
  superOver('super_over'),
  completed('completed'),
  abandoned('abandoned'),
  rescheduled('rescheduled'),
  walkover('walkover');

  const MatchStatus(this.wire);
  final String wire;
  static MatchStatus fromWire(String? w) =>
      values.where((s) => s.wire == w).firstOrNull ?? MatchStatus.scheduled;

  /// Confirmed-upcoming: cards in this state belong in the "Confirmed" tab on
  /// My Matches.
  bool get isUpcoming =>
      this == scheduled ||
      this == toss ||
      this == rescheduled;

  /// In-play.
  bool get isLive =>
      this == live || this == inningsBreak || this == superOver;

  /// Past — match has a final result (or terminal non-result).
  bool get isPast =>
      this == completed || this == abandoned || this == walkover;

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
