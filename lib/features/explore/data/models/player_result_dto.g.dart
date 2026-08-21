// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player_result_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PlayerResultDto _$PlayerResultDtoFromJson(Map<String, dynamic> json) =>
    _PlayerResultDto(
      playerType: json['player_type'] as String,
      id: json['id'] as String,
      name: json['name'] as String,
      username: json['username'] as String?,
      photoUrl: json['photo_url'] as String?,
      city: json['city'] as String?,
      playerRole: json['player_role'] as String?,
      battingStyle: json['batting_style'] as String?,
      bowlingStyle: json['bowling_style'] as String?,
      teamContext: json['team_context'] as String?,
      isVerified: json['is_verified'] as bool? ?? false,
      followerCount: (json['follower_count'] as num?)?.toInt() ?? 0,
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
    );

Map<String, dynamic> _$PlayerResultDtoToJson(_PlayerResultDto instance) =>
    <String, dynamic>{
      'player_type': instance.playerType,
      'id': instance.id,
      'name': instance.name,
      'username': instance.username,
      'photo_url': instance.photoUrl,
      'city': instance.city,
      'player_role': instance.playerRole,
      'batting_style': instance.battingStyle,
      'bowling_style': instance.bowlingStyle,
      'team_context': instance.teamContext,
      'is_verified': instance.isVerified,
      'follower_count': instance.followerCount,
      'score': instance.score,
    };
