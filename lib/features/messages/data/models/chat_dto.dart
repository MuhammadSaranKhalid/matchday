import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../teams/domain/entities/team.dart' show TeamId;
import '../../domain/entities/chat.dart';

part 'chat_dto.freezed.dart';
part 'chat_dto.g.dart';

/// Wire shape returned by the `list-my-chats` edge function. Each row is the
/// joined output of `chats` + my `chat_members` + the `teams` table + the
/// latest non-deleted message, plus a computed unread count.
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
        // v1 schema: only team chats. team_name is non-null for them; for
        // safety (future chat kinds) fall back to an empty string.
        name: teamName ?? '',
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
      );
}
