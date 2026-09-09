// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_innings_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MatchInningsDto _$MatchInningsDtoFromJson(Map<String, dynamic> json) =>
    _MatchInningsDto(
      inningsId: json['innings_id'] as String,
      matchId: json['match_id'] as String,
      inningsNumber: (json['innings_number'] as num).toInt(),
      battingTeamSide: json['batting_team_side'] as String,
      bowlingTeamSide: json['bowling_team_side'] as String,
      oversAllocated: (json['overs_allocated'] as num?)?.toDouble() ?? 20.0,
      isCompleted: json['is_completed'] as bool? ?? false,
      startTime: json['start_time'] as String?,
      endTime: json['end_time'] as String?,
    );

Map<String, dynamic> _$MatchInningsDtoToJson(_MatchInningsDto instance) =>
    <String, dynamic>{
      'innings_id': instance.inningsId,
      'match_id': instance.matchId,
      'innings_number': instance.inningsNumber,
      'batting_team_side': instance.battingTeamSide,
      'bowling_team_side': instance.bowlingTeamSide,
      'overs_allocated': instance.oversAllocated,
      'is_completed': instance.isCompleted,
      'start_time': instance.startTime,
      'end_time': instance.endTime,
    };
