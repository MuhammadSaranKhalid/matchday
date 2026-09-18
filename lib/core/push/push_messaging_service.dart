import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Thin wrapper over [FirebaseMessaging] (+ [FlutterLocalNotificationsPlugin]
/// for foreground display) so the rest of the app never imports those packages
/// directly. Cross-cutting platform infra (the push delivery channel) — it
/// lives in `core/`, has no domain/data of its own, and is consumed via
/// [pushMessagingServiceProvider].
///
/// The token is *written* to Supabase through the notifications repository
/// (`registerDeviceToken` / `revokeDeviceToken`); this service only obtains the
/// token, asks for permission, displays foreground notifications, and surfaces
/// tap deep-links.
class PushMessagingService {
  PushMessagingService(this._fm, this._local);
  final FirebaseMessaging _fm;
  final FlutterLocalNotificationsPlugin _local;

  bool _foregroundInit = false;

  /// The Android channel used for both foreground (local) and background (FCM
  /// `default_notification_channel_id`) notifications. High importance so they
  /// pop as a heads-up.
  static const _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'Notifications',
    description: 'Match challenges, results, and other alerts',
    importance: Importance.high,
  );

  /// Ask the OS for notification permission. True when granted (or provisional
  /// on iOS).
  Future<bool> requestPermission() async {
    final s = await _fm.requestPermission(alert: true, badge: true, sound: true);
    return s.authorizationStatus == AuthorizationStatus.authorized ||
        s.authorizationStatus == AuthorizationStatus.provisional;
  }

  /// The device's current FCM token. Null where it can't be obtained yet — e.g.
  /// an iOS simulator with no APNs token, or before permission is granted.
  Future<String?> getToken() => _fm.getToken();

  /// Emits a fresh token whenever FCM rotates it.
  Stream<String> get tokenRefreshes => _fm.onTokenRefresh;

  /// Drop the device's token (sign-out).
  Future<void> deleteToken() => _fm.deleteToken();

  /// Deep-link routes from notification taps that opened the app from the
  /// background (FCM displays the notification; the OS routes the tap here).
  Stream<String> get tapRoutes => FirebaseMessaging.onMessageOpenedApp
      .map((m) => m.data['route'])
      .where((r) => r is String && r.isNotEmpty)
      .cast<String>();

  /// The route from a notification tap that cold-started the app (terminated →
  /// tapped), if any.
  Future<String?> initialTapRoute() async {
    final m = await _fm.getInitialMessage();
    final r = m?.data['route'];
    return (r is String && r.isNotEmpty) ? r : null;
  }

  /// Create the channel, init the local-notifications plugin (taps →
  /// [onTapRoute]), and display a heads-up for every *foreground* FCM message —
  /// neither Android nor iOS auto-show those while the app is open. Idempotent.
  Future<void> initForegroundDisplay({
    required void Function(String route) onTapRoute,
  }) async {
    if (_foregroundInit) return;
    _foregroundInit = true;

    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    await _local.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (resp) {
        final route = resp.payload;
        if (route != null && route.isNotEmpty) onTapRoute(route);
      },
    );

    FirebaseMessaging.onMessage.listen(_showForeground);
  }

  /// Track the chat thread ID currently in focus on this device.
  /// When non-null and matching an incoming chat push, local heads-up
  /// notification is suppressed because messages are rendered live via Ably.
  String? activeChatId;

  void setActiveChat(String? chatId) {
    activeChatId = chatId;
  }

  void _showForeground(RemoteMessage message) {
    final n = message.notification;
    if (n == null) return; // data-only message — nothing to display

    // If the user is actively viewing this exact chat thread on this device,
    // suppress the foreground heads-up banner.
    final chatId = message.data['chat_id'];
    if (chatId != null && chatId == activeChatId) {
      return;
    }

    final route = message.data['route'];
    _local.show(
      message.hashCode,
      n.title,
      n.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: route is String ? route : null,
    );
  }
}
