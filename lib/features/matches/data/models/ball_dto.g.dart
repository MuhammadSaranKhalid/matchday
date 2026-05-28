// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ball_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BallDto _$BallDtoFromJson(Map<String, dynamic> json) => _BallDto(
  ballId: json['ball_id'] as String,
  matchId: json['match_id'] as String,
  inningsNumber: (json['innings_number'] as num).toInt(),
  seq: (json['seq'] as num).toInt(),
  overNumber: (json['over_number'] as num).toInt(),
  ballInOver: (json['ball_in_over'] as num).toInt(),
  isLegalDelivery: json['is_legal_delivery'] as bool? ?? true,
  ballType: json['ball_type'] as String? ?? 'legal',
  runsScored: (json['runs_scored'] as num?)?.toInt() ?? 0,
  extras: (json['extras'] as num?)?.toInt() ?? 0,
  isWicket: json['is_wicket'] as bool? ?? false,
  wicketType: json['wicket_type'] as String?,
  isFreeHit: json['is_free_hit'] as bool? ?? false,
  batsmanId: json['batsman_id'] as String?,
  nonStrikerId: json['non_striker_id'] as String?,
  bowlerId: json['bowler_id'] as String?,
  fielderId: json['fielder_id'] as String?,
  commentary: json['commentary'] as String?,
);

Map<String, dynamic> _$BallDtoToJson(_BallDto instance) => <String, dynamic>{
  'ball_id': instance.ballId,
  'match_id': instance.matchId,
  'innings_number': instance.inningsNumber,
  'seq': instance.seq,
  'over_number': instance.overNumber,
  'ball_in_over': instance.ballInOver,
  'is_legal_delivery': instance.isLegalDelivery,
  'ball_type': instance.ballType,
  'runs_scored': instance.runsScored,
  'extras': instance.extras,
  'is_wicket': instance.isWicket,
  'wicket_type': instance.wicketType,
  'is_free_hit': instance.isFreeHit,
  'batsman_id': instance.batsmanId,
  'non_striker_id': instance.nonStrikerId,
  'bowler_id': instance.bowlerId,
  'fielder_id': instance.fielderId,
  'commentary': instance.commentary,
};
