import 'package:equatable/equatable.dart';

/// One generated fixture, before it exists in the database.
///
/// Teams are nullable because a knockout draw is mostly *unresolved* at the
/// moment it is locked: only round one has known sides. Later rounds carry
/// [prevSlotAId] / [prevSlotBId] instead, and the winner is moved in by the
/// `match_advance_tournament_bracket` trigger as each result lands.
class DrawFixture extends Equatable {
  const DrawFixture({
    required this.slotId,
    required this.roundNumber,
    required this.matchNumber,
    required this.roundLabel,
    required this.scheduledStartTime,
    required this.venue,
    this.teamAId,
    this.teamBId,
    this.prevSlotAId,
    this.prevSlotBId,
  });

  /// Stable within one plan — `r2m1`. Feeder links reference these rather
  /// than match ids, because no match exists yet when the plan is built. The
  /// RPC maps slot ids to the rows it inserts in a second pass.
  final String slotId;

  /// 1-based. Round 1 is the first round played, not the final.
  final int roundNumber;

  /// 1-based within [roundNumber].
  final int matchNumber;

  /// "Quarter-Final", "Round 3" — what the fixture row prints.
  final String roundLabel;

  final DateTime scheduledStartTime;
  final String venue;

  /// Null when the side is decided by [prevSlotAId].
  final String? teamAId;
  final String? teamBId;

  /// The slot whose winner fills side A / side B.
  final String? prevSlotAId;
  final String? prevSlotBId;

  /// Both sides known — a round-one knockout tie, or any league fixture.
  bool get isResolved => teamAId != null && teamBId != null;

  /// "QF1", "SF2", "F", "M3" — the mono code the fixture row and the seeding
  /// preview print beside the pairing.
  String get shortCode => switch (roundLabel) {
        'Final' => 'F',
        'Semi-Final' => 'SF$matchNumber',
        'Quarter-Final' => 'QF$matchNumber',
        _ => 'M$matchNumber',
      };

  @override
  List<Object?> get props => [
        slotId,
        roundNumber,
        matchNumber,
        roundLabel,
        scheduledStartTime,
        venue,
        teamAId,
        teamBId,
        prevSlotAId,
        prevSlotBId,
      ];
}

/// A team that skips a round because the field is not a power of two.
class DrawBye extends Equatable {
  const DrawBye({
    required this.teamId,
    required this.roundNumber,
    required this.intoSlotId,
  });

  final String teamId;

  /// The round being skipped (always 1 today).
  final int roundNumber;

  /// The slot the team walks into.
  final String intoSlotId;

  @override
  List<Object?> get props => [teamId, roundNumber, intoSlotId];
}

/// The complete draw for a tournament: every round, in order.
///
/// Built by [buildDraw] and consumed by both the seeding preview and the lock
/// action, so what an organiser is shown is what gets published. Those were
/// two separate implementations once, and they disagreed about which team
/// took the bye.
class DrawPlan extends Equatable {
  const DrawPlan({
    this.fixtures = const [],
    this.byes = const [],
    this.roundCount = 0,
    this.unsupported,
  });

  final List<DrawFixture> fixtures;
  final List<DrawBye> byes;

  /// Total rounds, including ones made entirely of unresolved fixtures.
  final int roundCount;

  /// Set when the tournament type has no generator yet, naming the type. The
  /// caller shows this rather than publishing a draw of the wrong shape.
  final String? unsupported;

  bool get isEmpty => fixtures.isEmpty;

  /// The last fixture's date — what the preview calls the finish.
  DateTime? get lastDate => fixtures.isEmpty
      ? null
      : fixtures
          .map((f) => f.scheduledStartTime)
          .reduce((a, b) => b.isAfter(a) ? b : a);

  List<DrawFixture> fixturesInRound(int round) =>
      fixtures.where((f) => f.roundNumber == round).toList();

  @override
  List<Object?> get props => [fixtures, byes, roundCount, unsupported];
}
