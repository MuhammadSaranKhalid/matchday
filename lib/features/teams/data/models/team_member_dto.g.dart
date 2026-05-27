// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_member_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TeamMemberDto _$TeamMemberDtoFromJson(Map<String, dynamic> json) =>
    _TeamMemberDto(
      membershipId: json['membership_id'] as String,
      teamId: json['team_id'] as String,
      userId: json['user_id'] as String?,
      unclaimedId: json['unclaimed_id'] as String?,
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
      'user_id': instance.userId,
      'unclaimed_id': instance.unclaimedId,
      'jersey_number': instance.jerseyNumber,
      'role': instance.role,
      'added_by': instance.addedBy,
      'joined_at': instance.joinedAt,
      'updated_at': instance.updatedAt,
    };
