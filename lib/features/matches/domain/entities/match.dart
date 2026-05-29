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
    required this.createdBy,
    required this.createdAt,
    this.teamASquad = const [],
    this.teamBSquad = const [],
    this.teamACaptain,
    this.teamBCaptain,
    this.teamAKeeper,
    this.teamBKeeper,
    this.venue,
    this.scheduledStartTime,
    this.actualStartTime,
    this.resultDescription,
    this.tossWonBy,
    this.tossDecision,
    this.tossFace,
    this.startPhase = MatchStartPhase.toss,
    this.currentInnings,
    this.currentStrikerId,
    this.currentNonStrikerId,
    this.currentBowlerId,
    this.openersSubmittedBy,
    this.openersSubmittedAt,
  });

  final MatchId id;
  final TeamId teamAId;
  final TeamId teamBId;
  final MatchFormat format;
  final MatchStatus status;
  final String createdBy;
  final DateTime createdAt;

  /// Player ids (claimed user_ids or unclaimed ids) on each side's XI.
  final List<String> teamASquad;
  final List<String> teamBSquad;
  final String? teamACaptain;
  final String? teamBCaptain;
  final String? teamAKeeper;
  final String? teamBKeeper;
  final Venue? venue;
  final DateTime? scheduledStartTime;
  final DateTime? actualStartTime;

  /// Human-readable outcome once the match is completed (e.g. the final score).
  final String? resultDescription;

  // ── Match-start state (mirrors deployed `matches` row) ─────────────────────

  /// Team that won the toss (null until the host phone records it).
  final TeamId? tossWonBy;

  /// Bat / bowl decision by the toss winner.
  final TossDecision? tossDecision;

  /// Coin face the host phone observed. Cosmetic — used by the result banner.
  final String? tossFace;

  /// Where the match is in the pre-live → live progression.
  final MatchStartPhase startPhase;

  /// Active innings number (1 for innings 1, 2 for the chase, etc.).
  final int? currentInnings;

  /// Player ids (claimed or unclaimed) currently on strike / off strike /
  /// bowling. Populated by `submit_match_openers` (openers) and updated by
  /// every `record_ball` during scoring.
  final String? currentStrikerId;
  final String? currentNonStrikerId;
  final String? currentBowlerId;

  /// User_id of the captain who locked the openers. Drives the "Locked by
  /// Imran" caption + the EDIT PICKS affordance (only the locker can edit).
  final String? openersSubmittedBy;
  final DateTime? openersSubmittedAt;

  /// True when this match is in a state where participants are expected to
  /// act or observe — open, in-play, or recently concluded. Delegates to
  /// [MatchStatus.isActive].
  bool get isActive => status.isActive;

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
        currentInnings,
        currentStrikerId,
        currentNonStrikerId,
        currentBowlerId,
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

/// Match format: overs, players a side, ball type, bowling cap.
class MatchFormat extends Equatable {
  const MatchFormat({
    required this.oversPerInnings,
    required this.playersPerTeam,
    required this.ballType,
    required this.maxOversPerBowler,
  });

  final int oversPerInnings;
  final int playersPerTeam;
  final MatchBallType ballType;
  final int maxOversPerBowler;

  @override
  List<Object?> get props =>
      [oversPerInnings, playersPerTeam, ballType, maxOversPerBowler];
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
