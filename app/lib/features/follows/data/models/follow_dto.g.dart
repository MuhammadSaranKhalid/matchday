// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'follow_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FollowDto _$FollowDtoFromJson(Map<String, dynamic> json) => _FollowDto(
  followId: json['follow_id'] as String,
  followerId: json['follower_id'] as String,
  targetType: json['target_type'] as String,
  targetId: json['target_id'] as String,
  status: json['status'] as String? ?? 'active',
  notificationsEnabled: json['notifications_enabled'] as bool? ?? true,
  createdAt: json['created_at'] as String,
);

Map<String, dynamic> _$FollowDtoToJson(_FollowDto instance) =>
    <String, dynamic>{
      'follow_id': instance.followId,
      'follower_id': instance.followerId,
      'target_type': instance.targetType,
      'target_id': instance.targetId,
      'status': instance.status,
      'notifications_enabled': instance.notificationsEnabled,
      'created_at': instance.createdAt,
    };
