import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/error/failures.dart';

import '../../../auth/presentation/providers/auth_providers.dart';

import '../../data/datasources/notifications_datasource_providers.dart';
import '../../data/repositories/notifications_repository_impl.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../state/notifications_view.dart';

part 'notifications_providers.g.dart';

@Riverpod(keepAlive: true)
NotificationsRepository notificationsRepository(Ref ref) =>
    NotificationsRepositoryImpl(
      ref.watch(notificationsRemoteDataSourceProvider),
    );

/// Live notifications stream — the single source of truth driving the bell
/// badge and the inbox. keepAlive so the broadcast channel stays subscribed
/// across route changes.
@Riverpod(keepAlive: true)
Stream<NotificationFeed> liveNotifications(Ref ref) {
  final user = ref.watch(currentUserStreamProvider).value;
  if (user == null) return Stream.value(const NotificationFeed());
  return ref.watch(notificationsRepositoryProvider).watchMine();
}

/// Tier-grouped view-model derived from [liveNotifications].
@Riverpod(keepAlive: true)
NotificationsView notificationsView(Ref ref) {
  final feed =
      ref.watch(liveNotificationsProvider).value ?? const NotificationFeed();
  return NotificationsView.from(feed.items, unreadCount: feed.unreadCount);
}

/// Unread count — the value the bell badge renders. Cheap derived view.
@Riverpod(keepAlive: true)
int unreadNotificationsCount(Ref ref) =>
    ref.watch(notificationsViewProvider).unreadCount;

@riverpod
Future<List<NotificationSetting>> notificationSettings(Ref ref) async {
  ref.watch(currentUserStreamProvider);
  final result = await ref.watch(notificationsRepositoryProvider).settings();
  return result.fold((f) => throw FailureWrapper(f), (settings) => settings);
}
