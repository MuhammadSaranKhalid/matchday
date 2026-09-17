import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/chat_channel.dart';

part 'chat_channel_dto.freezed.dart';
part 'chat_channel_dto.g.dart';

/// Wire DTO returned by `list_my_chats` RPC.
@freezed
abstract class ChatChannelDto with _$ChatChannelDto {
  const factory ChatChannelDto({
    @JsonKey(name: 'channel_id') required String channelId,
    @JsonKey(name: 'channel_key') required String channelKey,
    @JsonKey(name: 'kind') required String kind,
    @JsonKey(name: 'context_type') required String contextType,
    @JsonKey(name: 'title') String? title,
    @JsonKey(name: 'team_id') String? teamId,
    @JsonKey(name: 'match_id') String? matchId,
    @JsonKey(name: 'last_message_seq') int? lastMessageSeq,
    @JsonKey(name: 'last_message_at') String? lastMessageAt,
    @JsonKey(name: 'team_name') String? teamName,
    @JsonKey(name: 'team_logo_url') String? teamLogoUrl,
    @JsonKey(name: 'team_logo_monogram') String? teamLogoMonogram,
    @JsonKey(name: 'team_primary_color') String? teamPrimaryColor,
    @JsonKey(name: 'dm_other_user_id') String? dmOtherUserId,
    @JsonKey(name: 'dm_other_user_name') String? dmOtherUserName,
    @JsonKey(name: 'dm_other_user_username') String? dmOtherUserUsername,
    @JsonKey(name: 'dm_other_user_avatar_url') String? dmOtherUserAvatarUrl,
    @JsonKey(name: 'you_follow') @Default(false) bool youFollow,
    @JsonKey(name: 'they_follow_you') @Default(false) bool theyFollowYou,
    @JsonKey(name: 'is_accepted') @Default(true) bool isAccepted,
    @JsonKey(name: 'is_pinned') @Default(false) bool isPinned,
    @JsonKey(name: 'is_archived') @Default(false) bool isArchived,
    @JsonKey(name: 'is_muted') @Default(false) bool isMuted,
    @JsonKey(name: 'pinned_at') String? pinnedAt,
    @JsonKey(name: 'archived_at') String? archivedAt,
    @JsonKey(name: 'notifications_muted_until') String? notificationsMutedUntil,
    @JsonKey(name: 'last_message_body') String? lastMessageBody,
    @JsonKey(name: 'last_message_sender_id') String? lastMessageSenderId,
    @JsonKey(name: 'last_message_from_me') @Default(false) bool lastMessageFromMe,
    @JsonKey(name: 'unread_count') @Default(0) int unreadCount,
    @JsonKey(name: 'last_read_message_seq') int? lastReadMessageSeq,
    @JsonKey(name: 'last_read_at') String? lastReadAt,
    @JsonKey(name: 'last_delivered_message_seq') int? lastDeliveredMessageSeq,
    @JsonKey(name: 'last_delivered_at') String? lastDeliveredAt,
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'updated_at') required String updatedAt,
  }) = _ChatChannelDto;

  const ChatChannelDto._();

  factory ChatChannelDto.fromJson(Map<String, dynamic> json) =>
      _$ChatChannelDtoFromJson(json);

  ChatChannel toEntity() => ChatChannel(
        id: channelId,
        channelKey: channelKey,
        kind: ChatChannelKind.fromWire(kind),
        contextType: ChatChannelContext.fromWire(contextType),
        name: title ?? teamName ?? dmOtherUserName ?? dmOtherUserUsername ?? '',
        teamId: teamId,
        matchId: matchId,
        lastMessageSeq: lastMessageSeq,
        lastMessageAt: lastMessageAt == null ? null : DateTime.parse(lastMessageAt!),
        lastMessagePreview: lastMessageBody,
        lastMessageSenderId: lastMessageSenderId,
        lastMessageFromMe: lastMessageFromMe,
        unreadCount: unreadCount,
        isAccepted: isAccepted,
        isPinned: isPinned,
        isArchived: isArchived,
        isMuted: isMuted,
        dmOtherUserId: dmOtherUserId,
        dmOtherUserName: dmOtherUserName,
        dmOtherUserUsername: dmOtherUserUsername,
        dmOtherUserAvatarUrl: dmOtherUserAvatarUrl,
        youFollow: youFollow,
        theyFollowYou: theyFollowYou,
        teamName: teamName,
        teamLogoUrl: teamLogoUrl,
        teamLogoMonogram: teamLogoMonogram,
        teamPrimaryColorHex: teamPrimaryColor,
        createdAt: DateTime.parse(createdAt),
        updatedAt: DateTime.parse(updatedAt),
      );
}
