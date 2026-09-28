// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cricket_player_profile_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CricketPlayerProfileDto _$CricketPlayerProfileDtoFromJson(
  Map<String, dynamic> json,
) => _CricketPlayerProfileDto(
  userId: json['user_id'] as String,
  sportId: json['sport_id'] as String? ?? 'cricket',
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

Map<String, dynamic> _$CricketPlayerProfileDtoToJson(
  _CricketPlayerProfileDto instance,
) => <String, dynamic>{
  'user_id': instance.userId,
  'sport_id': instance.sportId,
  'batting_style': instance.battingStyle,
  'bowling_style': instance.bowlingStyle,
  'player_role': instance.playerRole,
  'preferred_ball_types': instance.preferredBallTypes,
  'years_playing': instance.yearsPlaying,
};
