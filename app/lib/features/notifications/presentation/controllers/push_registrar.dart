import 'dart:async';

import 'package:flutter/foundation.dart'
    show
        TargetPlatform,
        debugPrint,
        defaultTargetPlatform;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/push/push_messaging_service.dart';
import '../../../../core/push/push_provider.dart';
import '../../../../core/supabase/supabase_auth_state_provider.dart';
import '../../../../router/app_router.dart';
import '../../domain/entities/app_notification.dart';
import '../providers/notifications_providers.dart';

part 'push_registrar.g.dart';

/// Application-scoped FCM token lifecycle + notification navigation.
///
/// Activated once from app.dart and kept alive for the session.
///
/// Responsibilities:
/// - initialize foreground notification presentation
/// - register the signed-in user's FCM token
/// - re-register token rotations
/// - route foreground/background/cold-start notification taps
/// - revoke the device token before sign-out
///
/// This controller intentionally does NOT decide whether a particular chat
/// notification should be suppressed. That visibility policy belongs to
/// PushMessagingService + MessageThreadScreen.
@Riverpod(keepAlive: true)
class PushRegistrar extends _$PushRegistrar {
  bool _registrationRunning = false;
  bool _registrationRequestedAgain = false;

  @override
  void build() {
    ref.listen<String?>(
      currentUserIdProvider,
      (previous, next) {
        if (next != null && next != previous) {
          unawaited(_register());
        }
      },
      fireImmediately: true,
    );

    final push = ref.read(pushMessagingServiceProvider);

    unawaited(_initializePushSurface(push));

    final refreshSubscription =
        push.tokenRefreshes.listen(
      (_) {
        unawaited(_register());
      },
      onError: (Object error, StackTrace stack) {
        debugPrint(
          '[PushRegistrar] '
          'FCM token refresh stream failed: '
          '$error\n$stack',
        );
      },
    );
    ref.onDispose(refreshSubscription.cancel);

    final tapSubscription = push.tapRoutes.listen(
      _go,
      onError: (Object error, StackTrace stack) {
        debugPrint(
          '[PushRegistrar] '
          'FCM notification-tap stream failed: '
          '$error\n$stack',
        );
      },
    );
    ref.onDispose(tapSubscription.cancel);
  }

  Future<void> _initializePushSurface(
    PushMessagingService push,
  ) async {
    try {
      await push.initForegroundDisplay(
        onTapRoute: _go,
      );

      final initialRoute = await push.initialTapRoute();
      if (initialRoute != null) {
        _go(initialRoute);
      }
    } catch (error, stack) {
      // Push UI failure is non-fatal to the rest of the application.
      debugPrint(
        '[PushRegistrar] '
        'push surface initialization failed: '
        '$error\n$stack',
      );
    }
  }

  /// Coalesces overlapping auth/token-refresh registrations.
  Future<void> _register() async {
    if (_registrationRunning) {
      _registrationRequestedAgain = true;
      return;
    }

    _registrationRunning = true;

    try {
      do {
        _registrationRequestedAgain = false;
        await _registerOnce();
      } while (_registrationRequestedAgain);
    } finally {
      _registrationRunning = false;
    }
  }

  Future<void> _registerOnce() async {
    final platform = _platform();
    if (platform == null) return;

    if (ref.read(currentUserIdProvider) == null) {
      return;
    }

    try {
      final push = ref.read(pushMessagingServiceProvider);

      if (!await push.requestPermission()) {
        debugPrint(
          '[PushRegistrar] notification permission not granted',
        );
        return;
      }

      final token = await push.getToken();
      if (token == null || token.trim().isEmpty) {
        debugPrint(
          '[PushRegistrar] FCM token unavailable',
        );
        return;
      }

      // Identity can change while native permission/token calls are in flight.
      if (ref.read(currentUserIdProvider) == null) {
        return;
      }

      final result = await ref
          .read(notificationsRepositoryProvider)
          .registerDeviceToken(
            fcmToken: token,
            platform: platform,
          );

      result.fold(
        (failure) {
          debugPrint(
            '[PushRegistrar] '
            'device-token registration failed: '
            '${failure.message}',
          );
        },
        (_) {
          debugPrint(
            '[PushRegistrar] device token registered',
          );
        },
      );
    } catch (error, stack) {
      debugPrint(
        '[PushRegistrar] '
        'device-token registration exception: '
        '$error\n$stack',
      );
    }
  }

  /// Must run while the Supabase user is still authenticated because server
  /// token revocation is RLS-scoped to auth.uid().
  Future<void> unregister() async {
    final push = ref.read(pushMessagingServiceProvider);

    try {
      final token = await push.getToken();

      if (token != null && token.trim().isNotEmpty) {
        final result = await ref
            .read(notificationsRepositoryProvider)
            .revokeDeviceToken(token);

        result.fold(
          (failure) {
            debugPrint(
              '[PushRegistrar] '
              'device-token revoke failed: '
              '${failure.message}',
            );
          },
          (_) {},
        );
      }
    } catch (error, stack) {
      debugPrint(
        '[PushRegistrar] '
        'device-token revoke exception: '
        '$error\n$stack',
      );
    } finally {
      try {
        await push.deleteToken();
      } catch (error, stack) {
        debugPrint(
          '[PushRegistrar] '
          'local FCM token deletion failed: '
          '$error\n$stack',
        );
      }
    }
  }

  void _go(String route) {
    final normalized = route.trim();
    if (normalized.isEmpty) return;

    try {
      ref.read(appRouterProvider).go(normalized);
    } catch (error, stack) {
      debugPrint(
        '[PushRegistrar] '
        'notification route failed ($normalized): '
        '$error\n$stack',
      );
    }
  }

  DevicePlatform? _platform() =>
      switch (defaultTargetPlatform) {
        TargetPlatform.iOS => DevicePlatform.ios,
        TargetPlatform.android => DevicePlatform.android,
        _ => null,
      };
}
