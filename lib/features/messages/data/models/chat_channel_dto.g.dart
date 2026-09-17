// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_channel_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ChatChannelDto _$ChatChannelDtoFromJson(Map<String, dynamic> json) =>
    _ChatChannelDto(
      channelId: json['chat_id'] as String,
      channelKey: json['channel_key'] as String,
      kind: json['kind'] as String,
      contextType: json['context_type'] as String,
      title: json['title'] as String?,
      teamId: json['team_id'] as String?,
      matchId: json['match_id'] as String?,
      lastMessageSeq: (json['last_message_seq'] as num?)?.toInt(),
      lastMessageAt: json['last_message_at'] as String?,
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
      isAccepted: json['is_accepted'] as bool? ?? true,
      isPinned: json['is_pinned'] as bool? ?? false,
      isArchived: json['is_archived'] as bool? ?? false,
      isMuted: json['is_muted'] as bool? ?? false,
      lastMessageBody: json['last_message_body'] as String?,
      lastMessageSenderId: json['last_message_sender_id'] as String?,
      lastMessageFromMe: json['last_message_from_me'] as bool? ?? false,
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );

Map<String, dynamic> _$ChatChannelDtoToJson(_ChatChannelDto instance) =>
    <String, dynamic>{
      'chat_id': instance.channelId,
      'channel_key': instance.channelKey,
      'kind': instance.kind,
      'context_type': instance.contextType,
      'title': instance.title,
      'team_id': instance.teamId,
      'match_id': instance.matchId,
      'last_message_seq': instance.lastMessageSeq,
      'last_message_at': instance.lastMessageAt,
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
      'is_accepted': instance.isAccepted,
      'is_pinned': instance.isPinned,
      'is_archived': instance.isArchived,
      'is_muted': instance.isMuted,
      'last_message_body': instance.lastMessageBody,
      'last_message_sender_id': instance.lastMessageSenderId,
      'last_message_from_me': instance.lastMessageFromMe,
      'unread_count': instance.unreadCount,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };
