// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_innings_state_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MatchInningsStateDto _$MatchInningsStateDtoFromJson(
  Map<String, dynamic> json,
) => _MatchInningsStateDto(
  matchId: json['match_id'] as String,
  inningsNumber: (json['innings_number'] as num).toInt(),
  strikerId: json['striker_id'] as String?,
  nonStrikerId: json['non_striker_id'] as String?,
  bowlerId: json['bowler_id'] as String?,
  legalBallCount: (json['legal_ball_count'] as num?)?.toInt() ?? 0,
  totalRuns: (json['total_runs'] as num?)?.toInt() ?? 0,
  totalWickets: (json['total_wickets'] as num?)?.toInt() ?? 0,
  totalExtras: (json['total_extras'] as num?)?.toInt() ?? 0,
  isDeclared: json['is_declared'] as bool? ?? false,
  isAllOut: json['is_all_out'] as bool? ?? false,
  target: (json['target'] as num?)?.toInt(),
  version: (json['version'] as num?)?.toInt() ?? 0,
  updatedAt: json['updated_at'] as String,
);

Map<String, dynamic> _$MatchInningsStateDtoToJson(
  _MatchInningsStateDto instance,
) => <String, dynamic>{
  'match_id': instance.matchId,
  'innings_number': instance.inningsNumber,
  'striker_id': instance.strikerId,
  'non_striker_id': instance.nonStrikerId,
  'bowler_id': instance.bowlerId,
  'legal_ball_count': instance.legalBallCount,
  'total_runs': instance.totalRuns,
  'total_wickets': instance.totalWickets,
  'total_extras': instance.totalExtras,
  'is_declared': instance.isDeclared,
  'is_all_out': instance.isAllOut,
  'target': instance.target,
  'version': instance.version,
  'updated_at': instance.updatedAt,
};
