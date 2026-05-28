import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/usecase/usecase.dart';
import '../../data/datasources/notifications_datasource_providers.dart';
import '../../data/repositories/notifications_repository_impl.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../../domain/usecases/mark_notification_read.dart';
import '../../domain/usecases/register_device_token.dart';
import '../../domain/usecases/watch_notifications.dart';
import '../state/notifications_view.dart';

part 'notifications_providers.g.dart';

@Riverpod(keepAlive: true)
NotificationsRepository notificationsRepository(Ref ref) =>
    NotificationsRepositoryImpl(
      ref.watch(notificationsRemoteDataSourceProvider),
    );

@riverpod
WatchNotifications watchNotificationsUseCase(Ref ref) =>
    WatchNotifications(ref.watch(notificationsRepositoryProvider));

@riverpod
MarkNotificationRead markNotificationReadUseCase(Ref ref) =>
    MarkNotificationRead(ref.watch(notificationsRepositoryProvider));

@riverpod
MarkAllNotificationsRead markAllNotificationsReadUseCase(Ref ref) =>
    MarkAllNotificationsRead(ref.watch(notificationsRepositoryProvider));

@riverpod
RegisterDeviceToken registerDeviceTokenUseCase(Ref ref) =>
    RegisterDeviceToken(ref.watch(notificationsRepositoryProvider));

@riverpod
RevokeDeviceToken revokeDeviceTokenUseCase(Ref ref) =>
    RevokeDeviceToken(ref.watch(notificationsRepositoryProvider));

/// Live notifications stream — the single source of truth driving the bell
/// badge and the inbox. keepAlive so the broadcast channel stays subscribed
/// across route changes.
@Riverpod(keepAlive: true)
Stream<List<AppNotification>> liveNotifications(Ref ref) =>
    ref.watch(watchNotificationsUseCaseProvider).call(const NoParams());

/// Tier-grouped view-model derived from [liveNotifications].
@Riverpod(keepAlive: true)
NotificationsView notificationsView(Ref ref) {
  final list = ref.watch(liveNotificationsProvider).value ?? const [];
  return NotificationsView.from(list);
}

/// Unread count — the value the bell badge renders. Cheap derived view.
@Riverpod(keepAlive: true)
int unreadNotificationsCount(Ref ref) =>
    ref.watch(notificationsViewProvider).unreadCount;
