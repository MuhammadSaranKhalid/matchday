// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_wicket_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MatchWicketDto _$MatchWicketDtoFromJson(Map<String, dynamic> json) =>
    _MatchWicketDto(
      wicketId: json['wicket_id'] as String,
      deliveryId: json['delivery_id'] as String,
      inningsId: json['innings_id'] as String,
      playerOutId: json['player_out_id'] as String,
      dismissalKind: json['dismissal_kind'] as String,
      isBowlerCredited: json['is_bowler_credited'] as bool? ?? true,
      creditedBowlerId: json['credited_bowler_id'] as String?,
      primaryFielderId: json['primary_fielder_id'] as String?,
      assistedFielderId: json['assisted_fielder_id'] as String?,
      fallOfWicketScore: (json['fall_of_wicket_score'] as num).toInt(),
      fallOfWicketNumber: (json['fall_of_wicket_number'] as num).toInt(),
      fallOfWicketOvers: (json['fall_of_wicket_overs'] as num).toDouble(),
      createdAt: json['created_at'] as String,
    );

Map<String, dynamic> _$MatchWicketDtoToJson(_MatchWicketDto instance) =>
    <String, dynamic>{
      'wicket_id': instance.wicketId,
      'delivery_id': instance.deliveryId,
      'innings_id': instance.inningsId,
      'player_out_id': instance.playerOutId,
      'dismissal_kind': instance.dismissalKind,
      'is_bowler_credited': instance.isBowlerCredited,
      'credited_bowler_id': instance.creditedBowlerId,
      'primary_fielder_id': instance.primaryFielderId,
      'assisted_fielder_id': instance.assistedFielderId,
      'fall_of_wicket_score': instance.fallOfWicketScore,
      'fall_of_wicket_number': instance.fallOfWicketNumber,
      'fall_of_wicket_overs': instance.fallOfWicketOvers,
      'created_at': instance.createdAt,
    };
