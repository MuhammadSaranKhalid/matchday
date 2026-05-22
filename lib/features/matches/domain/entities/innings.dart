import '../../../teams/domain/entities/team.dart';
import 'match.dart';

/// One innings of a match. Created at match start (F6); its running totals and
/// current striker/non-striker/bowler are mutated by ball-by-ball scoring (F8).
class Innings {
  const Innings({
    required this.id,
    required this.matchId,
    required this.inningsNumber,
    required this.battingTeamId,
    required this.bowlingTeamId,
    required this.status,
    this.totalRuns = 0,
    this.totalWickets = 0,
    this.totalOvers = 0,
    this.totalBallsFaced = 0,
    this.target,
    this.currentStrikerId,
    this.currentNonStrikerId,
    this.currentBowlerId,
  });

  final InningsId id;
  final MatchId matchId;
  final int inningsNumber;
  final TeamId battingTeamId;
  final TeamId bowlingTeamId;
  final InningsStatus status;
  final int totalRuns;
  final int totalWickets;
  final double totalOvers;
  final int totalBallsFaced;
  final int? target;
  final String? currentStrikerId;
  final String? currentNonStrikerId;
  final String? currentBowlerId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Innings &&
          other.id == id &&
          other.matchId == matchId &&
          other.inningsNumber == inningsNumber &&
          other.totalRuns == totalRuns &&
          other.totalWickets == totalWickets &&
          other.status == status;

  @override
  int get hashCode => Object.hash(
      id, matchId, inningsNumber, totalRuns, totalWickets, status);
}

class InningsId {
  const InningsId(this.value);
  final String value;
  @override
  bool operator ==(Object other) => other is InningsId && other.value == value;
  @override
  int get hashCode => value.hashCode;
  @override
  String toString() => value;
}

enum InningsStatus {
  notStarted('not_started'),
  inProgress('in_progress'),
  completed('completed'),
  declared('declared');

  const InningsStatus(this.wire);
  final String wire;
  static InningsStatus fromWire(String? w) =>
      values.where((s) => s.wire == w).firstOrNull ?? InningsStatus.inProgress;
}
