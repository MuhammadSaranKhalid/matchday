// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProfileDto _$ProfileDtoFromJson(Map<String, dynamic> json) => _ProfileDto(
  userId: json['user_id'] as String,
  username: json['username'] as String?,
  displayName: json['display_name'] as String?,
  location: json['location'] as Map<String, dynamic>?,
  onboardedAt: json['onboarded_at'] as String?,
  playerProfile:
      json['player_profile'] == null
          ? null
          : PlayerProfileDto.fromJson(
            json['player_profile'] as Map<String, dynamic>,
          ),
);

Map<String, dynamic> _$ProfileDtoToJson(_ProfileDto instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'username': instance.username,
      'display_name': instance.displayName,
      'location': instance.location,
      'onboarded_at': instance.onboardedAt,
      'player_profile': instance.playerProfile,
    };
