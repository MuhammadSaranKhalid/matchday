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
  'last_message_at': instance.lastMessageAt,
  'last_message_body': instance.lastMessageBody,
  'last_message_sender_id': instance.lastMessageSenderId,
  'last_message_from_me': instance.lastMessageFromMe,
  'unread_count': instance.unreadCount,
  'created_at': instance.createdAt,
  'updated_at': instance.updatedAt,
};
