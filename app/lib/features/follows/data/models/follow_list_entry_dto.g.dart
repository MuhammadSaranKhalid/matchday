// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'follow_list_entry_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FollowListEntryDto _$FollowListEntryDtoFromJson(Map<String, dynamic> json) =>
    _FollowListEntryDto(
      userId: json['user_id'] as String,
      displayName: json['display_name'] as String,
      username: json['username'] as String,
      avatarUrl: json['avatar_url'] as String?,
      youFollow: json['you_follow'] as bool,
      theyFollowYou: json['they_follow_you'] as bool,
    );

Map<String, dynamic> _$FollowListEntryDtoToJson(_FollowListEntryDto instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'display_name': instance.displayName,
      'username': instance.username,
      'avatar_url': instance.avatarUrl,
      'you_follow': instance.youFollow,
      'they_follow_you': instance.theyFollowYou,
    };
