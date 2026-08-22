import 'package:equatable/equatable.dart';

/// Materialized batting statistics for a player in a specific innings.
///
/// Backed by the `match_batsman_stats` table. Provides O(1) reads for scorecards
/// without requiring client-side computation over hundreds of deliveries.
class MatchBatsmanStats extends Equatable {
  const MatchBatsmanStats({
    required this.inningsId,
    required this.playerId,
    this.battingPosition,
    this.runs = 0,
    this.ballsFaced = 0,
    this.dots = 0,
    this.fours = 0,
    this.sixes = 0,
    this.singles = 0,
    this.doubles = 0,
    this.triples = 0,
    this.isOut = false,
    this.dismissalText,
    this.minutesBatted,
  });

  final String inningsId;
  final String playerId;
  final int? battingPosition;
  final int runs;
  final int ballsFaced;
  final int dots;
  final int fours;
  final int sixes;
  final int singles;
  final int doubles;
  final int triples;
  final bool isOut;
  final String? dismissalText;
  final int? minutesBatted;

  /// Strike rate calculation (Runs / Balls * 100).
  double get strikeRate {
    if (ballsFaced == 0) return 0.0;
    return (runs / ballsFaced) * 100.0;
  }

  /// True if the batter is not out and currently at the crease.
  bool get isNotOut => !isOut;

  @override
  List<Object?> get props => [
        inningsId,
        playerId,
        battingPosition,
        runs,
        ballsFaced,
        dots,
        fours,
        sixes,
        isOut,
        dismissalText,
      ];
}
