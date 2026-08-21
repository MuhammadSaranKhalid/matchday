// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_result_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MatchResultDto _$MatchResultDtoFromJson(Map<String, dynamic> json) =>
    _MatchResultDto(
      matchId: json['match_id'] as String,
      status: json['status'] as String,
      venue: json['venue'] as String?,
      tournamentName: json['tournament_name'] as String?,
      scheduledStartTime: json['scheduled_start_time'] as String?,
      actualStartTime: json['actual_start_time'] as String?,
      teamAId: json['team_a_id'] as String?,
      teamAName: json['team_a_name'] as String?,
      teamAColors: json['team_a_colors'] as Map<String, dynamic>?,
      teamALogo: json['team_a_logo'] as String?,
      teamBId: json['team_b_id'] as String?,
      teamBName: json['team_b_name'] as String?,
      teamBColors: json['team_b_colors'] as Map<String, dynamic>?,
      teamBLogo: json['team_b_logo'] as String?,
      inningsNumber: (json['innings_number'] as num?)?.toInt(),
      totalRuns: (json['total_runs'] as num?)?.toInt(),
      totalWickets: (json['total_wickets'] as num?)?.toInt(),
      legalBallCount: (json['legal_ball_count'] as num?)?.toInt(),
      target: (json['target'] as num?)?.toInt(),
      battingTeamId: json['batting_team_id'] as String?,
    );

Map<String, dynamic> _$MatchResultDtoToJson(_MatchResultDto instance) =>
    <String, dynamic>{
      'match_id': instance.matchId,
      'status': instance.status,
      'venue': instance.venue,
      'tournament_name': instance.tournamentName,
      'scheduled_start_time': instance.scheduledStartTime,
      'actual_start_time': instance.actualStartTime,
      'team_a_id': instance.teamAId,
      'team_a_name': instance.teamAName,
      'team_a_colors': instance.teamAColors,
      'team_a_logo': instance.teamALogo,
      'team_b_id': instance.teamBId,
      'team_b_name': instance.teamBName,
      'team_b_colors': instance.teamBColors,
      'team_b_logo': instance.teamBLogo,
      'innings_number': instance.inningsNumber,
      'total_runs': instance.totalRuns,
      'total_wickets': instance.totalWickets,
      'legal_ball_count': instance.legalBallCount,
      'target': instance.target,
      'batting_team_id': instance.battingTeamId,
    };
