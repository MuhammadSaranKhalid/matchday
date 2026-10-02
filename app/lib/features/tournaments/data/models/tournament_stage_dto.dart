import '../../domain/entities/tournament_stage.dart';

/// Wire-format DTO for `public.tournament_stages` rows.
class TournamentStageDto {
  const TournamentStageDto({
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
  final String competitionFormat;
  final String state;
  final Map<String, dynamic> competitionConfig;
  final Map<String, dynamic> sportRulesOverride;
  final String createdAt;
  final String updatedAt;

  factory TournamentStageDto.fromJson(Map<String, dynamic> json) {
    return TournamentStageDto(
      stageId: json['stage_id'] as String,
      tournamentId: json['tournament_id'] as String,
      sequence: json['sequence'] as int? ?? 1,
      name: json['name'] as String? ?? 'Stage',
      competitionFormat: json['competition_format'] as String? ?? 'single_elimination',
      state: json['state'] as String? ?? 'pending',
      competitionConfig: (json['competition_config'] as Map<String, dynamic>?) ?? const {},
      sportRulesOverride: (json['sport_rules_override'] as Map<String, dynamic>?) ?? const {},
      createdAt: json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      updatedAt: json['updated_at'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stage_id': stageId,
      'tournament_id': tournamentId,
      'sequence': sequence,
      'name': name,
      'competition_format': competitionFormat,
      'state': state,
      'competition_config': competitionConfig,
      'sport_rules_override': sportRulesOverride,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  TournamentStage toEntity() {
    return TournamentStage(
      stageId: stageId,
      tournamentId: tournamentId,
      sequence: sequence,
      name: name,
      competitionFormat: TournamentStageFormat.fromWire(competitionFormat),
      state: TournamentStageState.fromWire(state),
      competitionConfig: competitionConfig,
      sportRulesOverride: sportRulesOverride,
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
    );
  }
}
