import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/match_result.dart';

part 'match_result_dto.freezed.dart';
part 'match_result_dto.g.dart';

/// One row from `search-all`'s match group (and the browse live rail).
///
/// Flat team columns rather than nested team objects — the function joins
/// both sides and the row renders them side by side, so nesting would only
/// add an indirection.
@freezed
abstract class MatchResultDto with _$MatchResultDto {
  const factory MatchResultDto({
    @JsonKey(name: 'match_id') required String matchId,
    required String status,
    String? venue,
    @JsonKey(name: 'tournament_name') String? tournamentName,
    @JsonKey(name: 'scheduled_start_time') String? scheduledStartTime,
    @JsonKey(name: 'actual_start_time') String? actualStartTime,
    @JsonKey(name: 'team_a_id') String? teamAId,
    @JsonKey(name: 'team_a_name') String? teamAName,
    @JsonKey(name: 'team_a_colors') Map<String, dynamic>? teamAColors,
    @JsonKey(name: 'team_a_logo') String? teamALogo,
    @JsonKey(name: 'team_b_id') String? teamBId,
    @JsonKey(name: 'team_b_name') String? teamBName,
    @JsonKey(name: 'team_b_colors') Map<String, dynamic>? teamBColors,
    @JsonKey(name: 'team_b_logo') String? teamBLogo,
    @JsonKey(name: 'innings_number') int? inningsNumber,
    @JsonKey(name: 'total_runs') int? totalRuns,
    @JsonKey(name: 'total_wickets') int? totalWickets,
    @JsonKey(name: 'legal_ball_count') int? legalBallCount,
    int? target,
    @JsonKey(name: 'batting_team_id') String? battingTeamId,
  }) = _MatchResultDto;

  const MatchResultDto._();

  factory MatchResultDto.fromJson(Map<String, dynamic> json) =>
      _$MatchResultDtoFromJson(json);

  MatchResult toEntity() => MatchResult(
        matchId: matchId,
        status: status,
        venue: venue,
        tournamentName: tournamentName,
        scheduledStartTime: _parse(scheduledStartTime),
        actualStartTime: _parse(actualStartTime),
        teamAId: teamAId,
        teamAName: teamAName,
        teamAColor: teamAColors?['primary'] as String?,
        teamALogoUrl: teamALogo,
        teamBId: teamBId,
        teamBName: teamBName,
        teamBColor: teamBColors?['primary'] as String?,
        teamBLogoUrl: teamBLogo,
        inningsNumber: inningsNumber,
        totalRuns: totalRuns,
        totalWickets: totalWickets,
        legalBallCount: legalBallCount,
        target: target,
        battingTeamId: battingTeamId,
      );

  /// Timestamps arrive as ISO 8601 strings. A malformed one must not take the
  /// whole result list down — a match with an unreadable time still renders.
  static DateTime? _parse(String? raw) =>
      raw == null ? null : DateTime.tryParse(raw);
}
