import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/chat.dart' show ChatId;
import '../../domain/entities/message.dart';

part 'message_dto.freezed.dart';
part 'message_dto.g.dart';

/// Wire shape for one row of `messages`, with the sender's display name
/// flattened in by the data source (which queries `messages.select(
/// '*, sender:profiles(display_name)')` and lifts `sender.display_name`
/// to `sender_display_name`). [fromMe] is also precomputed by the data
/// source against the current user id so the presentation never has to
/// re-check auth.
@freezed
abstract class MessageDto with _$MessageDto {
  const factory MessageDto({
    @JsonKey(name: 'message_id') required String messageId,
    @JsonKey(name: 'chat_id') required String chatId,
    @JsonKey(name: 'sender_id') String? senderId,
    @JsonKey(name: 'sender_display_name') String? senderDisplayName,
    required String body,
    @JsonKey(name: 'message_type') @Default('text') String messageType,
    @JsonKey(name: 'payload') Map<String, dynamic>? payload,
    @JsonKey(name: 'reply_to_id') String? replyToId,
    @JsonKey(name: 'reply_to_body') String? replyToBody,
    @JsonKey(name: 'reply_to_author') String? replyToAuthor,
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'edited_at') String? editedAt,
    @JsonKey(name: 'deleted_at') String? deletedAt,
    @JsonKey(name: 'from_me') @Default(false) bool fromMe,
  }) = _MessageDto;

  const MessageDto._();

  factory MessageDto.fromJson(Map<String, dynamic> json) =>
      _$MessageDtoFromJson(json);

  Message toEntity() => Message(
        id: MessageId(messageId),
        chatId: ChatId(chatId),
        senderId: senderId,
        senderDisplayName: senderDisplayName,
        body: body,
        messageType: messageType,
        mediaUrl: payload?['media_url'] as String? ?? payload?['image_url'] as String?,
        replyToId: replyToId,
        replyToBody: replyToBody,
        replyToAuthor: replyToAuthor,
        createdAt: DateTime.parse(createdAt),
        editedAt: editedAt == null ? null : DateTime.parse(editedAt!),
        deletedAt: deletedAt == null ? null : DateTime.parse(deletedAt!),
        fromMe: fromMe,
      );
}
