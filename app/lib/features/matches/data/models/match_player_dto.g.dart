// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_player_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MatchPlayerDto _$MatchPlayerDtoFromJson(Map<String, dynamic> json) =>
    _MatchPlayerDto(
      matchPlayerId: json['match_player_id'] as String,
      matchId: json['match_id'] as String,
      teamSide: json['team_side'] as String,
      profileId: json['profile_id'] as String?,
      unclaimedId: json['unclaimed_id'] as String?,
      battingOrder: (json['batting_order'] as num?)?.toInt(),
      jerseyNumber: (json['jersey_number'] as num?)?.toInt(),
      isCaptain: json['is_captain'] as bool? ?? false,
      isKeeper: json['is_keeper'] as bool? ?? false,
      isSubstitute: json['is_substitute'] as bool? ?? false,
      source: json['source'] as String? ?? 'team_snapshot',
      profile: json['profile'] as Map<String, dynamic>?,
      unclaimed: json['unclaimed'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$MatchPlayerDtoToJson(_MatchPlayerDto instance) =>
    <String, dynamic>{
      'match_player_id': instance.matchPlayerId,
      'match_id': instance.matchId,
      'team_side': instance.teamSide,
      'profile_id': instance.profileId,
      'unclaimed_id': instance.unclaimedId,
      'batting_order': instance.battingOrder,
      'jersey_number': instance.jerseyNumber,
      'is_captain': instance.isCaptain,
      'is_keeper': instance.isKeeper,
      'is_substitute': instance.isSubstitute,
      'source': instance.source,
    };
