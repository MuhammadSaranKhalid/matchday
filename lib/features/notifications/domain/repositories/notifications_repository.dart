import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/app_notification.dart';

/// Online-only notifications contract. Reads ride the deployed
/// `user:<user_id>:notifications` broadcast channel; writes hit RLS-scoped
/// tables directly (no RPCs needed).
abstract class NotificationsRepository {
  String? iconUrl(String? path);
  Future<Either<Failure, List<NotificationSetting>>> settings();
  Future<Either<Failure, Unit>> setPreference(
    String category,
    String channel,
    bool enabled,
  );

  /// One-shot list of the signed-in user's notifications, newest first.
  Future<Either<Failure, List<AppNotification>>> listMine();

  /// Realtime feed for the current user's notifications. Subscribes to the
  /// `user:<id>:notifications` broadcast channel and emits the full list
  /// after each insert/update, newest first. Initial hydration via a
  /// one-shot SELECT.
  Stream<NotificationFeed> watchMine();

  Future<Either<Failure, Unit>> loadMore();

  /// Direct UPDATE on the notifications row (RLS scopes to recipient_id).
  Future<Either<Failure, Unit>> markRead(NotificationId id);

  /// Mark every unread notification as read in one round-trip.
  Future<Either<Failure, Unit>> markAllRead();

  /// Upsert the caller's FCM token for this device. RLS allows a self-insert
  /// when `auth.uid() = user_id`. Re-registering the same token bumps
  /// `last_seen_at` (handled server-side by the set_updated_at trigger).
  Future<Either<Failure, Unit>> registerDeviceToken({
    required String fcmToken,
    required DevicePlatform platform,
    String? appVersion,
  });

  /// Drop a device-token row on sign-out so the server stops pushing to it.
  Future<Either<Failure, Unit>> revokeDeviceToken(String fcmToken);
}
