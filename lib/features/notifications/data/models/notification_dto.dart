import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/app_notification.dart';

part 'notification_dto.freezed.dart';
part 'notification_dto.g.dart';

/// Wire-format `public.notifications` row.
///
/// `type` became `type_key` on 2026-09-12, and the row now carries its own
/// rendered `title` / `body` / `route` / `tier` / `icon` (see
/// `supabase/migrations/20260101000500_notifications.sql`). The DTO maps them
/// straight through — there is no per-type logic here and there must not be.
@freezed
abstract class NotificationDto with _$NotificationDto {
  const factory NotificationDto({
    @JsonKey(name: 'notification_id') required String notificationId,
    @JsonKey(name: 'recipient_id') required String recipientId,
    @JsonKey(name: 'type_key') required String typeKey,
    required String title,
    required String body,
    String? route,
    @Default('fyi') String tier,
    @Default('bell') String icon,
    @JsonKey(name: 'icon_path') String? iconPath,
    @Default('neutral') String tone,
    @JsonKey(name: 'actor_id') String? actorId,
    @JsonKey(name: 'entity_scope') String? entityScope,
    @JsonKey(name: 'entity_id') String? entityId,
    @JsonKey(name: 'group_count') @Default(1) int groupCount,
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
    typeKey: typeKey,
    title: title,
    body: body,
    route: route,
    tier: NotificationTier.fromWire(tier),
    icon: icon,
    iconPath: iconPath,
    tone: tone,
    actorId: actorId,
    entityScope: entityScope,
    entityId: entityId,
    groupCount: groupCount,
    payload: payload,
    isRead: isRead,
    createdAt: DateTime.parse(createdAt),
  );
}

class NotificationFeedDto {
  const NotificationFeedDto({
    this.items = const [],
    this.unreadCount = 0,
    this.hasMore = false,
    this.loadingMore = false,
  });
  final List<NotificationDto> items;
  final int unreadCount;
  final bool hasMore;
  final bool loadingMore;
  NotificationFeed toEntity() => NotificationFeed(
    items: items.map((n) => n.toEntity()).toList(),
    unreadCount: unreadCount,
    hasMore: hasMore,
    loadingMore: loadingMore,
  );
}
