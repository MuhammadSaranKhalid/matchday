// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_NotificationDto _$NotificationDtoFromJson(Map<String, dynamic> json) =>
    _NotificationDto(
      notificationId: json['notification_id'] as String,
      recipientId: json['recipient_id'] as String,
      typeKey: json['type_key'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      route: json['route'] as String?,
      tier: json['tier'] as String? ?? 'fyi',
      icon: json['icon'] as String? ?? 'bell',
      iconPath: json['icon_path'] as String?,
      tone: json['tone'] as String? ?? 'neutral',
      actorId: json['actor_id'] as String?,
      entityScope: json['entity_scope'] as String?,
      entityId: json['entity_id'] as String?,
      groupCount: (json['group_count'] as num?)?.toInt() ?? 1,
      payload:
          json['payload'] as Map<String, dynamic>? ?? const <String, dynamic>{},
      isRead: json['is_read'] as bool? ?? false,
      createdAt: json['created_at'] as String,
    );

Map<String, dynamic> _$NotificationDtoToJson(_NotificationDto instance) =>
    <String, dynamic>{
      'notification_id': instance.notificationId,
      'recipient_id': instance.recipientId,
      'type_key': instance.typeKey,
      'title': instance.title,
      'body': instance.body,
      'route': instance.route,
      'tier': instance.tier,
      'icon': instance.icon,
      'icon_path': instance.iconPath,
      'tone': instance.tone,
      'actor_id': instance.actorId,
      'entity_scope': instance.entityScope,
      'entity_id': instance.entityId,
      'group_count': instance.groupCount,
      'payload': instance.payload,
      'is_read': instance.isRead,
      'created_at': instance.createdAt,
    };
