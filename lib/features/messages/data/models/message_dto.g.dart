// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MessageDto _$MessageDtoFromJson(Map<String, dynamic> json) => _MessageDto(
  messageId: json['message_id'] as String,
  chatId: json['chat_id'] as String,
  senderId: json['sender_id'] as String?,
  senderDisplayName: json['sender_display_name'] as String?,
  body: json['body'] as String,
  createdAt: json['created_at'] as String,
  editedAt: json['edited_at'] as String?,
  deletedAt: json['deleted_at'] as String?,
  fromMe: json['from_me'] as bool? ?? false,
);

Map<String, dynamic> _$MessageDtoToJson(_MessageDto instance) =>
    <String, dynamic>{
      'message_id': instance.messageId,
      'chat_id': instance.chatId,
      'sender_id': instance.senderId,
      'sender_display_name': instance.senderDisplayName,
      'body': instance.body,
      'created_at': instance.createdAt,
      'edited_at': instance.editedAt,
      'deleted_at': instance.deletedAt,
      'from_me': instance.fromMe,
    };
