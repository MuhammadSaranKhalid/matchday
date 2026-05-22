import '../../../teams/domain/entities/team.dart';

/// A match between two teams. Online-only (Phase 1) — no offline mirror, no LWW.
///
/// In the setup flow (F4) a match is created in [MatchStatus.pending] with only
/// team A's side filled in; team B's squad/captain and the status transition are
/// the opponent's job (F5).
class Match {
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Match &&
          other.id == id &&
          other.teamAId == teamAId &&
          other.teamBId == teamBId &&
          other.status == status &&
          other.scheduledStartTime == scheduledStartTime;

  @override
  int get hashCode =>
      Object.hash(id, teamAId, teamBId, status, scheduledStartTime);
}

class MatchId {
  const MatchId(this.value);
  final String value;
  @override
  bool operator ==(Object other) => other is MatchId && other.value == value;
  @override
  int get hashCode => value.hashCode;
  @override
  String toString() => value;
}

/// Match format: overs, players a side, ball type, bowling cap.
class MatchFormat {
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
  bool operator ==(Object other) =>
      other is MatchFormat &&
      other.oversPerInnings == oversPerInnings &&
      other.playersPerTeam == playersPerTeam &&
      other.ballType == ballType &&
      other.maxOversPerBowler == maxOversPerBowler;

  @override
  int get hashCode =>
      Object.hash(oversPerInnings, playersPerTeam, ballType, maxOversPerBowler);
}

class Venue {
  const Venue({required this.ground, this.city});
  final String ground;
  final String? city;

  @override
  bool operator ==(Object other) =>
      other is Venue && other.ground == ground && other.city == city;
  @override
  int get hashCode => Object.hash(ground, city);
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

enum MatchStatus {
  pending('pending'),
  accepted('accepted'),
  declined('declined'),
  scheduled('scheduled'),
  toss('toss'),
  live('live'),
  inningsBreak('innings_break'),
  completed('completed'),
  abandoned('abandoned'),
  cancelled('cancelled');

  const MatchStatus(this.wire);
  final String wire;
  static MatchStatus fromWire(String? w) =>
      values.where((s) => s.wire == w).firstOrNull ?? MatchStatus.pending;
}
