import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/app_notification.dart';

part 'notification_dto.freezed.dart';
part 'notification_dto.g.dart';

/// Wire-format `public.notifications` row.
@freezed
abstract class NotificationDto with _$NotificationDto {
  const factory NotificationDto({
    @JsonKey(name: 'notification_id') required String notificationId,
    @JsonKey(name: 'recipient_id') required String recipientId,
    required String type,
    @Default(<String, dynamic>{}) Map<String, dynamic> payload,
    @JsonKey(name: 'is_read') @Default(false) bool isRead,
    @JsonKey(name: 'created_at') required String createdAt,
  }) = _NotificationDto;

  const NotificationDto._();

  factory NotificationDto.fromJson(Map<String, dynamic> json) =>
      _$NotificationDtoFromJson(json);

  AppNotification toEntity() => AppNotification(
        id: NotificationId(notificationId),
        recipientId: recipientId,
        type: NotificationType.fromWire(type),
        payload: payload,
        isRead: isRead,
        createdAt: DateTime.parse(createdAt),
      );
}
