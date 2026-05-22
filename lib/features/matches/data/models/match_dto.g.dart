// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MatchDto _$MatchDtoFromJson(Map<String, dynamic> json) => _MatchDto(
  matchId: json['match_id'] as String,
  teamAId: json['team_a_id'] as String,
  teamBId: json['team_b_id'] as String,
  teamASquad:
      (json['team_a_squad'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
  teamBSquad:
      (json['team_b_squad'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
  teamACaptain: json['team_a_captain'] as String?,
  teamBCaptain: json['team_b_captain'] as String?,
  teamAKeeper: json['team_a_keeper'] as String?,
  teamBKeeper: json['team_b_keeper'] as String?,
  format: json['format'] as Map<String, dynamic>,
  venue: json['venue'] as Map<String, dynamic>?,
  scheduledStartTime: json['scheduled_start_time'] as String?,
  result: json['result'] as Map<String, dynamic>?,
  status: json['status'] as String? ?? 'pending',
  createdBy: json['created_by'] as String,
  createdAt: json['created_at'] as String,
);

Map<String, dynamic> _$MatchDtoToJson(_MatchDto instance) => <String, dynamic>{
  'match_id': instance.matchId,
  'team_a_id': instance.teamAId,
  'team_b_id': instance.teamBId,
  'team_a_squad': instance.teamASquad,
  'team_b_squad': instance.teamBSquad,
  'team_a_captain': instance.teamACaptain,
  'team_b_captain': instance.teamBCaptain,
  'team_a_keeper': instance.teamAKeeper,
  'team_b_keeper': instance.teamBKeeper,
  'format': instance.format,
  'venue': instance.venue,
  'scheduled_start_time': instance.scheduledStartTime,
  'result': instance.result,
  'status': instance.status,
  'created_by': instance.createdBy,
  'created_at': instance.createdAt,
};
