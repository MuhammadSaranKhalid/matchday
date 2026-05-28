import '../../../teams/domain/entities/team.dart';
import 'match.dart';

/// Per-team innings totals aggregated from the `balls` table. The deployed
/// schema has NO innings table — totals are derived (runs scored + extras
/// summed; wickets = count where is_wicket; balls faced = count of legal
/// deliveries).
///
/// This is a passive value object — produced by
/// [MatchesRepository.listInningsForMatches] for past-tile scores on My
/// Matches and any scorecard view.
class InningsSummary {
  const InningsSummary({
    required this.matchId,
    required this.inningsNumber,
    required this.battingTeamId,
    required this.totalRuns,
    required this.totalWickets,
    required this.legalBallsFaced,
  });

  final MatchId matchId;
  final int inningsNumber;
  final TeamId battingTeamId;
  final int totalRuns;
  final int totalWickets;

  /// Count of legal deliveries faced. Display as overs via
  /// `legalBallsFaced ~/ 6 . legalBallsFaced % 6`.
  final int legalBallsFaced;

  double get totalOvers {
    final overs = legalBallsFaced ~/ 6;
    final rem = legalBallsFaced % 6;
    return overs + rem / 10.0;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InningsSummary &&
          other.matchId == matchId &&
          other.inningsNumber == inningsNumber &&
          other.totalRuns == totalRuns &&
          other.totalWickets == totalWickets;

  @override
  int get hashCode =>
      Object.hash(matchId, inningsNumber, totalRuns, totalWickets);
}
