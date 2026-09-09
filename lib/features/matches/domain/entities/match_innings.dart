import 'package:equatable/equatable.dart';

import 'match.dart';

/// The DEFINITION of an innings: who bats, for how long, and whether it
/// finished. Everything that changes ball to ball — the totals, the on-field
/// trio, the target — lives on [MatchInningsState] and only there.
///
/// The completed-match screen needs this because [MatchWicket]s are keyed by
/// `innings_id`, a uuid that appears nowhere else on the client: deliveries
/// carry an innings *number*, so without these rows there is no way to ask for
/// the fall of wickets.
class MatchInnings extends Equatable {
  const MatchInnings({
    required this.inningsId,
    required this.matchId,
    required this.inningsNumber,
    required this.battingTeamSide,
    required this.bowlingTeamSide,
    required this.oversAllocated,
    required this.isCompleted,
    this.startTime,
    this.endTime,
  });

  final String inningsId;
  final MatchId matchId;
  final int inningsNumber;

  /// 'team_a' or 'team_b' — the wire spelling, as stored.
  final String battingTeamSide;
  final String bowlingTeamSide;

  final double oversAllocated;
  final bool isCompleted;
  final DateTime? startTime;
  final DateTime? endTime;

  /// 'a' / 'b', to compare against [MatchPlayer.teamSide].
  String get battingSideLetter =>
      battingTeamSide.endsWith('b') ? 'b' : 'a';

  @override
  List<Object?> get props => [
        inningsId,
        matchId,
        inningsNumber,
        battingTeamSide,
        bowlingTeamSide,
        oversAllocated,
        isCompleted,
        startTime,
        endTime,
      ];
}
