// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player_profile_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PlayerProfileDto _$PlayerProfileDtoFromJson(Map<String, dynamic> json) =>
    _PlayerProfileDto(
      userId: json['user_id'] as String,
      battingStyle: json['batting_style'] as String?,
      bowlingStyle: json['bowling_style'] as String?,
      playerRole: json['player_role'] as String?,
      preferredBallTypes:
          (json['preferred_ball_types'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      yearsPlaying: (json['years_playing'] as num?)?.toInt(),
    );

Map<String, dynamic> _$PlayerProfileDtoToJson(_PlayerProfileDto instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'batting_style': instance.battingStyle,
      'bowling_style': instance.bowlingStyle,
      'player_role': instance.playerRole,
      'preferred_ball_types': instance.preferredBallTypes,
      'years_playing': instance.yearsPlaying,
    };
