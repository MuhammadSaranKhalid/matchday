import 'package:equatable/equatable.dart';

/// Execution state of a tournament fixture.
enum TournamentFixtureState {
  unresolved('unresolved', 'Unresolved'),
  ready('ready', 'Ready'),
  inProgress('in_progress', 'In Progress'),
  completed('completed', 'Completed'),
  abandoned('abandoned', 'Abandoned'),
  cancelled('cancelled', 'Cancelled'),
  bye('bye', 'Bye');

  const TournamentFixtureState(this.wire, this.label);
  final String wire;
  final String label;

  static TournamentFixtureState fromWire(String? wire) =>
      values.where((s) => s.wire == wire).firstOrNull ??
      TournamentFixtureState.unresolved;
}

/// Structural unit of competitive pairing in a tournament stage.
class TournamentFixture extends Equatable {
  const TournamentFixture({
    required this.fixtureId,
    required this.tournamentId,
    required this.stageId,
    required this.roundId,
    required this.drawRevisionId,
    required this.fixtureNumber,
    required this.state,
    this.scheduledStartTime,
    this.venueId,
    this.venueNameFallback,
    this.competitionConfigOverride = const {},
    this.sportRulesOverride = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  final String fixtureId;
  final String tournamentId;
  final String stageId;
  final String roundId;
  final String drawRevisionId;
  final int fixtureNumber;
  final TournamentFixtureState state;
  final DateTime? scheduledStartTime;
  final String? venueId;
  final String? venueNameFallback;
  final Map<String, dynamic> competitionConfigOverride;
  final Map<String, dynamic> sportRulesOverride;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [
        fixtureId,
        tournamentId,
        stageId,
        roundId,
        drawRevisionId,
        fixtureNumber,
        state,
        scheduledStartTime,
        venueId,
        venueNameFallback,
        competitionConfigOverride,
        sportRulesOverride,
        createdAt,
        updatedAt,
      ];
}
