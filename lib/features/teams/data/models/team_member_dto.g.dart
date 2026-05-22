// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_member_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TeamMemberDto _$TeamMemberDtoFromJson(Map<String, dynamic> json) =>
    _TeamMemberDto(
      membershipId: json['membership_id'] as String,
      teamId: json['team_id'] as String,
      playerId: json['player_id'] as String,
      playerType: json['player_type'] as String,
      jerseyNumber: (json['jersey_number'] as num?)?.toInt(),
      role: json['role'] as String? ?? 'player',
      addedBy: json['added_by'] as String,
      joinedAt: json['joined_at'] as String,
      updatedAt: json['updated_at'] as String,
    );

Map<String, dynamic> _$TeamMemberDtoToJson(_TeamMemberDto instance) =>
    <String, dynamic>{
      'membership_id': instance.membershipId,
      'team_id': instance.teamId,
      'player_id': instance.playerId,
      'player_type': instance.playerType,
      'jersey_number': instance.jerseyNumber,
      'role': instance.role,
      'added_by': instance.addedBy,
      'joined_at': instance.joinedAt,
      'updated_at': instance.updatedAt,
    };
