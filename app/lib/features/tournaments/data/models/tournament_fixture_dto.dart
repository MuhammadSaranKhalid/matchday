import '../../domain/entities/tournament_fixture.dart';

/// Wire-format DTO for `public.tournament_fixtures` rows.
class TournamentFixtureDto {
  const TournamentFixtureDto({
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
  final String state;
  final String? scheduledStartTime;
  final String? venueId;
  final String? venueNameFallback;
  final Map<String, dynamic> competitionConfigOverride;
  final Map<String, dynamic> sportRulesOverride;
  final String createdAt;
  final String updatedAt;

  factory TournamentFixtureDto.fromJson(Map<String, dynamic> json) {
    return TournamentFixtureDto(
      fixtureId: json['fixture_id'] as String,
      tournamentId: json['tournament_id'] as String,
      stageId: json['stage_id'] as String,
      roundId: json['round_id'] as String,
      drawRevisionId: json['draw_revision_id'] as String,
      fixtureNumber: json['fixture_number'] as int? ?? 1,
      state: json['state'] as String? ?? 'unresolved',
      scheduledStartTime: json['scheduled_start_time'] as String?,
      venueId: json['venue_id'] as String?,
      venueNameFallback: json['venue_name_fallback'] as String?,
      competitionConfigOverride: (json['competition_config_override'] as Map<String, dynamic>?) ?? const {},
      sportRulesOverride: (json['sport_rules_override'] as Map<String, dynamic>?) ?? const {},
      createdAt: json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      updatedAt: json['updated_at'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fixture_id': fixtureId,
      'tournament_id': tournamentId,
      'stage_id': stageId,
      'round_id': roundId,
      'draw_revision_id': drawRevisionId,
      'fixture_number': fixtureNumber,
      'state': state,
      'scheduled_start_time': scheduledStartTime,
      'venue_id': venueId,
      'venue_name_fallback': venueNameFallback,
      'competition_config_override': competitionConfigOverride,
      'sport_rules_override': sportRulesOverride,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  TournamentFixture toEntity() {
    return TournamentFixture(
      fixtureId: fixtureId,
      tournamentId: tournamentId,
      stageId: stageId,
      roundId: roundId,
      drawRevisionId: drawRevisionId,
      fixtureNumber: fixtureNumber,
      state: TournamentFixtureState.fromWire(state),
      scheduledStartTime: scheduledStartTime != null ? DateTime.tryParse(scheduledStartTime!) : null,
      venueId: venueId,
      venueNameFallback: venueNameFallback,
      competitionConfigOverride: competitionConfigOverride,
      sportRulesOverride: sportRulesOverride,
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
    );
  }
}
