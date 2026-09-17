import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/chat_message.dart';
import '../../domain/entities/message_attachment.dart';
import '../../domain/entities/message_reaction.dart';

part 'chat_message_dto.freezed.dart';
part 'chat_message_dto.g.dart';

/// Wire shape for one row of `messages` along with joined relations.
@freezed
abstract class ChatMessageDto with _$ChatMessageDto {
  const factory ChatMessageDto({
    @JsonKey(name: 'message_id') required String messageId,
    @JsonKey(name: 'message_seq') int? messageSeq,
    @JsonKey(name: 'channel_id') required String channelId,
    @JsonKey(name: 'sender_id') String? senderId,
    @JsonKey(name: 'sender_display_name') String? senderDisplayName,
    @JsonKey(name: 'message_type') @Default('text') String messageType,
    @JsonKey(name: 'body') String? body,
    @JsonKey(name: 'payload') @Default({}) Map<String, dynamic> payload,
    @JsonKey(name: 'reply_to_message_id') String? replyToMessageId,
    @JsonKey(name: 'reply_to_body') String? replyToBody,
    @JsonKey(name: 'reply_to_author') String? replyToAuthor,
    @JsonKey(name: 'version') @Default(1) int version,
    @JsonKey(name: 'counts_as_unread') @Default(true) bool countsAsUnread,
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'updated_at') String? updatedAt,
    @JsonKey(name: 'edited_at') String? editedAt,
    @JsonKey(name: 'deleted_at') String? deletedAt,
    @JsonKey(name: 'from_me') @Default(false) bool fromMe,
    @JsonKey(name: 'attachments')
    @Default([])
    List<ChatMessageAttachmentDto> attachments,
    @JsonKey(name: 'reactions')
    @Default([])
    List<ChatMessageReactionDto> reactions,
  }) = _ChatMessageDto;

  const ChatMessageDto._();

  factory ChatMessageDto.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageDtoFromJson(json);

  ChatMessage toEntity({
    String syncStatus = 'sent',
    MessageDeliveryStatus deliveryStatus = MessageDeliveryStatus.sent,
  }) =>
      ChatMessage(
        id: messageId,
        messageSeq: messageSeq,
        channelId: channelId,
        senderId: senderId,
        senderDisplayName: senderDisplayName,
        messageType: messageType,
        body: body,
        payload: payload,
        replyToId: replyToMessageId,
        replyToBody: replyToBody,
        replyToAuthor: replyToAuthor,
        version: version,
        createdAt: DateTime.parse(createdAt),
        editedAt: editedAt == null ? null : DateTime.parse(editedAt!),
        deletedAt: deletedAt == null ? null : DateTime.parse(deletedAt!),
        fromMe: fromMe,
        syncStatus: syncStatus,
        deliveryStatus: deliveryStatus,
        attachments: attachments.map((a) => a.toEntity()).toList(),
        reactions: reactions.map((r) => r.toEntity()).toList(),
      );
}

@freezed
abstract class ChatMessageAttachmentDto with _$ChatMessageAttachmentDto {
  const factory ChatMessageAttachmentDto({
    @JsonKey(name: 'attachment_id') required String attachmentId,
    @JsonKey(name: 'message_id') required String messageId,
    @JsonKey(name: 'storage_path') String? storagePath,
    @JsonKey(name: 'mime_type') required String mimeType,
    @JsonKey(name: 'file_name') String? fileName,
    @JsonKey(name: 'size_bytes') int? sizeBytes,
    @JsonKey(name: 'width') int? width,
    @JsonKey(name: 'height') int? height,
    @JsonKey(name: 'duration_ms') int? durationMs,
  }) = _ChatMessageAttachmentDto;

  const ChatMessageAttachmentDto._();

  factory ChatMessageAttachmentDto.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageAttachmentDtoFromJson(json);

  MessageAttachment toEntity({
    String? localPath,
    String? thumbnailLocalPath,
    String uploadStatus = 'uploaded',
  }) =>
      MessageAttachment(
        id: attachmentId,
        messageId: messageId,
        storagePath: storagePath,
        mimeType: mimeType,
        fileName: fileName,
        sizeBytes: sizeBytes,
        width: width,
        height: height,
        durationMs: durationMs,
        localPath: localPath,
        thumbnailLocalPath: thumbnailLocalPath,
        uploadStatus: uploadStatus,
      );
}

@freezed
abstract class ChatMessageReactionDto with _$ChatMessageReactionDto {
  const factory ChatMessageReactionDto({
    @JsonKey(name: 'message_id') required String messageId,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'reaction') required String reaction,
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'removed_at') String? removedAt,
  }) = _ChatMessageReactionDto;

  const ChatMessageReactionDto._();

  factory ChatMessageReactionDto.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageReactionDtoFromJson(json);

  MessageReaction toEntity() => MessageReaction(
        messageId: messageId,
        userId: userId,
        reaction: reaction,
        createdAt: DateTime.parse(createdAt),
        isRemoved: removedAt != null,
      );
}
