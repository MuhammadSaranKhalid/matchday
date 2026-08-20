import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/push/push_provider.dart';
import '../../../../router/app_router.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/app_notification.dart';
import '../providers/notifications_providers.dart';

part 'push_registrar.g.dart';

/// Drives the FCM token lifecycle + notification-tap deep links for the
/// signed-in user. Activated once (app.dart watches it); keepAlive for the
/// session.
///
/// - On sign-in (or app start while already signed in): request permission →
///   fetch the FCM token → register it via the notifications repository.
/// - On token rotation: re-register.
/// - On a notification tap: deep-link via the router.
/// - On sign-out: [unregister] is invoked from the auth controller *before* the
///   session ends, because the RLS delete on `device_tokens` needs
///   `auth.uid()`.
@Riverpod(keepAlive: true)
class PushRegistrar extends _$PushRegistrar {
  @override
  void build() {
    // Register whenever a user becomes present (fresh sign-in).
    ref.listen(currentUserStreamProvider, (prev, next) {
      if (prev?.value == null && next.value != null) _register();
    });
    // ...and once now if a session already exists at startup.
    if (ref.read(currentUserStreamProvider).value != null) _register();

    final push = ref.read(pushMessagingServiceProvider);

    // Show a heads-up for foreground messages (the OS only auto-displays
    // background/killed ones); taps deep-link via the router.
    push.initForegroundDisplay(onTapRoute: _go);

    final refreshSub = push.tokenRefreshes.listen((_) => _register());
    ref.onDispose(refreshSub.cancel);

    final tapSub = push.tapRoutes.listen(_go);
    ref.onDispose(tapSub.cancel);

    // Cold-start tap (app launched from a terminated-state notification).
    push.initialTapRoute().then((r) {
      if (r != null) _go(r);
    });
  }

  /// Best-effort — a failed registration just means no push until the next
  /// token refresh or app start.
  ///
  /// The catch-all is load-bearing: when Play services can't reach Firebase
  /// Installations the FCM channel *throws* (`SERVICE_NOT_AVAILABLE`) rather
  /// than yielding a null token, and this runs fire-and-forget from [build],
  /// so an escaping error would land as an unhandled async exception.
  Future<void> _register() async {
    final platform = _platform();
    if (platform == null) return; // mobile-only — skip web/desktop
    try {
      final push = ref.read(pushMessagingServiceProvider);
      if (!await push.requestPermission()) return;
      final token = await push.getToken();
      if (token == null) return;
      await ref
          .read(notificationsRepositoryProvider)
          .registerDeviceToken(fcmToken: token, platform: platform);
    } catch (_) {/* no push this session — retried on refresh/next start */}
  }

  /// Revoke this device's token server-side, then drop it locally. MUST run
  /// while still authenticated (RLS scopes the delete to `auth.uid()`), so the
  /// auth controller calls this just before `signOut()`.
  Future<void> unregister() async {
    final push = ref.read(pushMessagingServiceProvider);
    final token = await push.getToken();
    if (token != null) {
      await ref.read(notificationsRepositoryProvider).revokeDeviceToken(token);
    }
    await push.deleteToken();
  }

  void _go(String route) => ref.read(appRouterProvider).go(route);

  DevicePlatform? _platform() => switch (defaultTargetPlatform) {
        TargetPlatform.iOS => DevicePlatform.ios,
        TargetPlatform.android => DevicePlatform.android,
        _ => null,
      };
}
