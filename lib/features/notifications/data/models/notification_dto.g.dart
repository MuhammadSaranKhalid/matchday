// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_NotificationDto _$NotificationDtoFromJson(Map<String, dynamic> json) =>
    _NotificationDto(
      notificationId: json['notification_id'] as String,
      recipientId: json['recipient_id'] as String,
      type: json['type'] as String,
      payload:
          json['payload'] as Map<String, dynamic>? ?? const <String, dynamic>{},
      isRead: json['is_read'] as bool? ?? false,
      createdAt: json['created_at'] as String,
    );

Map<String, dynamic> _$NotificationDtoToJson(_NotificationDto instance) =>
    <String, dynamic>{
      'notification_id': instance.notificationId,
      'recipient_id': instance.recipientId,
      'type': instance.type,
      'payload': instance.payload,
      'is_read': instance.isRead,
      'created_at': instance.createdAt,
    };
