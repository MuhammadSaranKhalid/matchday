import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../teams/domain/entities/team.dart' show TeamId;
import '../../domain/entities/chat.dart';

part 'chat_dto.freezed.dart';
part 'chat_dto.g.dart';

/// Wire shape returned by `list_my_chats` RPC / edge function.
@freezed
abstract class ChatDto with _$ChatDto {
  const factory ChatDto({
    @JsonKey(name: 'chat_id') required String chatId,
    required String type,
    @JsonKey(name: 'team_id') String? teamId,
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
    @JsonKey(name: 'last_message_at') String? lastMessageAt,
    @JsonKey(name: 'last_message_body') String? lastMessageBody,
    @JsonKey(name: 'last_message_sender_id') String? lastMessageSenderId,
    @JsonKey(name: 'last_message_from_me') @Default(false) bool lastMessageFromMe,
    @JsonKey(name: 'unread_count') @Default(0) int unreadCount,
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'updated_at') required String updatedAt,
  }) = _ChatDto;

  const ChatDto._();

  factory ChatDto.fromJson(Map<String, dynamic> json) => _$ChatDtoFromJson(json);

  Chat toEntity() => Chat(
        id: ChatId(chatId),
        kind: ChatKind.fromWire(type),
        name: teamName ?? dmOtherUserName ?? dmOtherUserUsername ?? '',
        teamId: teamId == null ? null : TeamId(teamId!),
        unreadCount: unreadCount,
        createdAt: DateTime.parse(createdAt),
        updatedAt: DateTime.parse(updatedAt),
        lastMessageAt: lastMessageAt == null ? null : DateTime.parse(lastMessageAt!),
        lastMessagePreview: lastMessageBody,
        lastMessageSenderId: lastMessageSenderId,
        lastMessageFromMe: lastMessageFromMe,
        teamLogoUrl: teamLogoUrl,
        teamLogoMonogram: teamLogoMonogram,
        teamPrimaryColorHex: teamPrimaryColor,
        dmOtherUserId: dmOtherUserId,
        dmOtherUserName: dmOtherUserName,
        dmOtherUserUsername: dmOtherUserUsername,
        dmOtherUserAvatarUrl: dmOtherUserAvatarUrl,
        youFollow: youFollow,
        theyFollowYou: theyFollowYou,
        isAccepted: isAccepted,
      );
}
