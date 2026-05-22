// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ball_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BallDto _$BallDtoFromJson(Map<String, dynamic> json) => _BallDto(
  ballId: json['ball_id'] as String,
  inningsId: json['innings_id'] as String,
  matchId: json['match_id'] as String,
  overNumber: (json['over_number'] as num).toInt(),
  ballNumber: (json['ball_number'] as num).toInt(),
  legalBallNumber: (json['legal_ball_number'] as num).toInt(),
  bowlerId: json['bowler_id'] as String,
  strikerId: json['striker_id'] as String,
  nonStrikerId: json['non_striker_id'] as String,
  runsScored: (json['runs_scored'] as num?)?.toInt() ?? 0,
  extraRuns: (json['extra_runs'] as num?)?.toInt() ?? 0,
  extraType: json['extra_type'] as String?,
  totalRuns: (json['total_runs'] as num?)?.toInt() ?? 0,
  isFour: json['is_four'] as bool? ?? false,
  isSix: json['is_six'] as bool? ?? false,
  isWicket: json['is_wicket'] as bool? ?? false,
  wicketType: json['wicket_type'] as String?,
  dismissedPlayerId: json['dismissed_player_id'] as String?,
);

Map<String, dynamic> _$BallDtoToJson(_BallDto instance) => <String, dynamic>{
  'ball_id': instance.ballId,
  'innings_id': instance.inningsId,
  'match_id': instance.matchId,
  'over_number': instance.overNumber,
  'ball_number': instance.ballNumber,
  'legal_ball_number': instance.legalBallNumber,
  'bowler_id': instance.bowlerId,
  'striker_id': instance.strikerId,
  'non_striker_id': instance.nonStrikerId,
  'runs_scored': instance.runsScored,
  'extra_runs': instance.extraRuns,
  'extra_type': instance.extraType,
  'total_runs': instance.totalRuns,
  'is_four': instance.isFour,
  'is_six': instance.isSix,
  'is_wicket': instance.isWicket,
  'wicket_type': instance.wicketType,
  'dismissed_player_id': instance.dismissedPlayerId,
};
