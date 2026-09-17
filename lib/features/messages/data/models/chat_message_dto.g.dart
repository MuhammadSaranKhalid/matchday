// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_message_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ChatMessageDto _$ChatMessageDtoFromJson(
  Map<String, dynamic> json,
) => _ChatMessageDto(
  messageId: json['message_id'] as String,
  messageSeq: (json['message_seq'] as num?)?.toInt(),
  channelId: json['channel_id'] as String,
  senderId: json['sender_id'] as String?,
  senderDisplayName: json['sender_display_name'] as String?,
  messageType: json['message_type'] as String? ?? 'text',
  body: json['body'] as String?,
  payload: json['payload'] as Map<String, dynamic>? ?? const {},
  replyToMessageId: json['reply_to_message_id'] as String?,
  replyToBody: json['reply_to_body'] as String?,
  replyToAuthor: json['reply_to_author'] as String?,
  version: (json['version'] as num?)?.toInt() ?? 1,
  countsAsUnread: json['counts_as_unread'] as bool? ?? true,
  createdAt: json['created_at'] as String,
  updatedAt: json['updated_at'] as String?,
  editedAt: json['edited_at'] as String?,
  deletedAt: json['deleted_at'] as String?,
  fromMe: json['from_me'] as bool? ?? false,
  attachments:
      (json['attachments'] as List<dynamic>?)
          ?.map(
            (e) => ChatMessageAttachmentDto.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const [],
  reactions:
      (json['reactions'] as List<dynamic>?)
          ?.map(
            (e) => ChatMessageReactionDto.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const [],
);

Map<String, dynamic> _$ChatMessageDtoToJson(_ChatMessageDto instance) =>
    <String, dynamic>{
      'message_id': instance.messageId,
      'message_seq': instance.messageSeq,
      'channel_id': instance.channelId,
      'sender_id': instance.senderId,
      'sender_display_name': instance.senderDisplayName,
      'message_type': instance.messageType,
      'body': instance.body,
      'payload': instance.payload,
      'reply_to_message_id': instance.replyToMessageId,
      'reply_to_body': instance.replyToBody,
      'reply_to_author': instance.replyToAuthor,
      'version': instance.version,
      'counts_as_unread': instance.countsAsUnread,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
      'edited_at': instance.editedAt,
      'deleted_at': instance.deletedAt,
      'from_me': instance.fromMe,
      'attachments': instance.attachments,
      'reactions': instance.reactions,
    };

_ChatMessageAttachmentDto _$ChatMessageAttachmentDtoFromJson(
  Map<String, dynamic> json,
) => _ChatMessageAttachmentDto(
  attachmentId: json['attachment_id'] as String,
  messageId: json['message_id'] as String,
  storagePath: json['storage_path'] as String?,
  mimeType: json['mime_type'] as String,
  fileName: json['file_name'] as String?,
  sizeBytes: (json['size_bytes'] as num?)?.toInt(),
  width: (json['width'] as num?)?.toInt(),
  height: (json['height'] as num?)?.toInt(),
  durationMs: (json['duration_ms'] as num?)?.toInt(),
);

Map<String, dynamic> _$ChatMessageAttachmentDtoToJson(
  _ChatMessageAttachmentDto instance,
) => <String, dynamic>{
  'attachment_id': instance.attachmentId,
  'message_id': instance.messageId,
  'storage_path': instance.storagePath,
  'mime_type': instance.mimeType,
  'file_name': instance.fileName,
  'size_bytes': instance.sizeBytes,
  'width': instance.width,
  'height': instance.height,
  'duration_ms': instance.durationMs,
};

_ChatMessageReactionDto _$ChatMessageReactionDtoFromJson(
  Map<String, dynamic> json,
) => _ChatMessageReactionDto(
  messageId: json['message_id'] as String,
  userId: json['user_id'] as String,
  reaction: json['reaction'] as String,
  createdAt: json['created_at'] as String,
  removedAt: json['removed_at'] as String?,
);

Map<String, dynamic> _$ChatMessageReactionDtoToJson(
  _ChatMessageReactionDto instance,
) => <String, dynamic>{
  'message_id': instance.messageId,
  'user_id': instance.userId,
  'reaction': instance.reaction,
  'created_at': instance.createdAt,
  'removed_at': instance.removedAt,
};
