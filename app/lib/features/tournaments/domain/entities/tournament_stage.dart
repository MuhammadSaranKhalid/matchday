import 'package:equatable/equatable.dart';

/// Supported competition formats for a tournament stage.
enum TournamentStageFormat {
  singleElimination('single_elimination', 'Single Elimination'),
  doubleElimination('double_elimination', 'Double Elimination'),
  roundRobin('round_robin', 'Round Robin'),
  swiss('swiss', 'Swiss'),
  custom('custom', 'Custom');

  const TournamentStageFormat(this.wire, this.label);
  final String wire;
  final String label;

  static TournamentStageFormat fromWire(String? wire) =>
      values.where((f) => f.wire == wire).firstOrNull ??
      TournamentStageFormat.singleElimination;
}

/// Operational state of a tournament stage.
enum TournamentStageState {
  pending('pending', 'Pending'),
  active('active', 'Active'),
  completed('completed', 'Completed'),
  cancelled('cancelled', 'Cancelled');

  const TournamentStageState(this.wire, this.label);
  final String wire;
  final String label;

  static TournamentStageState fromWire(String? wire) =>
      values.where((s) => s.wire == wire).firstOrNull ??
      TournamentStageState.pending;
}

/// Canonical competition stage within a tournament.
class TournamentStage extends Equatable {
  const TournamentStage({
    required this.stageId,
    required this.tournamentId,
    required this.sequence,
    required this.name,
    required this.competitionFormat,
    required this.state,
    this.competitionConfig = const {},
    this.sportRulesOverride = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  final String stageId;
  final String tournamentId;
  final int sequence;
  final String name;
  final TournamentStageFormat competitionFormat;
  final TournamentStageState state;
  final Map<String, dynamic> competitionConfig;
  final Map<String, dynamic> sportRulesOverride;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [
        stageId,
        tournamentId,
        sequence,
        name,
        competitionFormat,
        state,
        competitionConfig,
        sportRulesOverride,
        createdAt,
        updatedAt,
      ];
}
