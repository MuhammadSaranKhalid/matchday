import 'package:equatable/equatable.dart';

/// Materialized bowling statistics for a player in a specific innings.
///
/// Backed by the `match_bowler_stats` table. Provides O(1) reads for scorecards
/// without requiring client-side computation over hundreds of deliveries.
class MatchBowlerStats extends Equatable {
  const MatchBowlerStats({
    required this.inningsId,
    required this.playerId,
    this.bowlingPosition,
    this.legalBallsBowled = 0,
    this.maidens = 0,
    this.runsConceded = 0,
    this.wickets = 0,
    this.widesConceded = 0,
    this.noBallsConceded = 0,
    this.dotBallsBowled = 0,
  });

  final String inningsId;
  final String playerId;
  final int? bowlingPosition;
  final int legalBallsBowled;
  final int maidens;
  final int runsConceded;
  final int wickets;
  final int widesConceded;
  final int noBallsConceded;
  final int dotBallsBowled;

  /// Formatted overs string (e.g. 3.4 for 22 balls, or 4.0 for 24 balls).
  String get oversFormatted {
    final completedOvers = legalBallsBowled ~/ 6;
    final remainingBalls = legalBallsBowled % 6;
    return '$completedOvers.$remainingBalls';
  }

  /// Exact fractional overs bowled (for calculating economy).
  double get oversFractional {
    final completedOvers = legalBallsBowled ~/ 6;
    final remainingBalls = legalBallsBowled % 6;
    return completedOvers + (remainingBalls / 6.0);
  }

  /// Economy rate calculation (Runs / Overs).
  double get economyRate {
    final overs = oversFractional;
    if (overs == 0) return 0.0;
    return runsConceded / overs;
  }

  @override
  List<Object?> get props => [
        inningsId,
        playerId,
        bowlingPosition,
        legalBallsBowled,
        maidens,
        runsConceded,
        wickets,
        widesConceded,
        noBallsConceded,
        dotBallsBowled,
      ];
}
