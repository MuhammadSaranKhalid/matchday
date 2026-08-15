// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ChatDto _$ChatDtoFromJson(Map<String, dynamic> json) => _ChatDto(
  chatId: json['chat_id'] as String,
  type: json['type'] as String,
  teamId: json['team_id'] as String?,
  teamName: json['team_name'] as String?,
  teamLogoUrl: json['team_logo_url'] as String?,
  teamLogoMonogram: json['team_logo_monogram'] as String?,
  teamPrimaryColor: json['team_primary_color'] as String?,
  dmOtherUserId: json['dm_other_user_id'] as String?,
  dmOtherUserName: json['dm_other_user_name'] as String?,
  dmOtherUserUsername: json['dm_other_user_username'] as String?,
  dmOtherUserAvatarUrl: json['dm_other_user_avatar_url'] as String?,
  youFollow: json['you_follow'] as bool? ?? false,
  theyFollowYou: json['they_follow_you'] as bool? ?? false,
  lastMessageAt: json['last_message_at'] as String?,
  lastMessageBody: json['last_message_body'] as String?,
  lastMessageSenderId: json['last_message_sender_id'] as String?,
  lastMessageFromMe: json['last_message_from_me'] as bool? ?? false,
  unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
  createdAt: json['created_at'] as String,
  updatedAt: json['updated_at'] as String,
);

Map<String, dynamic> _$ChatDtoToJson(_ChatDto instance) => <String, dynamic>{
  'chat_id': instance.chatId,
  'type': instance.type,
  'team_id': instance.teamId,
  'team_name': instance.teamName,
  'team_logo_url': instance.teamLogoUrl,
  'team_logo_monogram': instance.teamLogoMonogram,
  'team_primary_color': instance.teamPrimaryColor,
  'dm_other_user_id': instance.dmOtherUserId,
  'dm_other_user_name': instance.dmOtherUserName,
  'dm_other_user_username': instance.dmOtherUserUsername,
  'dm_other_user_avatar_url': instance.dmOtherUserAvatarUrl,
  'you_follow': instance.youFollow,
  'they_follow_you': instance.theyFollowYou,
  'last_message_at': instance.lastMessageAt,
  'last_message_body': instance.lastMessageBody,
  'last_message_sender_id': instance.lastMessageSenderId,
  'last_message_from_me': instance.lastMessageFromMe,
  'unread_count': instance.unreadCount,
  'created_at': instance.createdAt,
  'updated_at': instance.updatedAt,
};
