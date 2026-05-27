// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unclaimed_player_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UnclaimedPlayerDto _$UnclaimedPlayerDtoFromJson(Map<String, dynamic> json) =>
    _UnclaimedPlayerDto(
      unclaimedId: json['unclaimed_id'] as String,
      displayName: json['display_name'] as String,
      addedBy: json['added_by'] as String,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      playerProfile:
          json['player_profile'] as Map<String, dynamic>? ??
          const <String, dynamic>{},
    );

Map<String, dynamic> _$UnclaimedPlayerDtoToJson(_UnclaimedPlayerDto instance) =>
    <String, dynamic>{
      'unclaimed_id': instance.unclaimedId,
      'display_name': instance.displayName,
      'added_by': instance.addedBy,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
      'player_profile': instance.playerProfile,
    };
