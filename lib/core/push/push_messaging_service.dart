import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Device-side push surface for Matchday.
///
/// Responsibilities:
/// - request notification permission
/// - expose FCM token/token rotations
/// - create the Android chat notification channel
/// - display foreground heads-up notifications
/// - expose background/terminated notification tap routes
/// - suppress a foreground notification only while that exact chat thread is
///   genuinely visible
///
/// Recipient selection, blocks, mutes, preferences and notification copy are
/// server responsibilities. This class never decides who should receive a push.
class PushMessagingService {
  PushMessagingService(
    this._fm,
    this._local,
  );

  final FirebaseMessaging _fm;
  final FlutterLocalNotificationsPlugin _local;

  /// IMPORTANT:
  ///
  /// This ID is part of a cross-layer contract shared with:
  /// - android/app/src/main/AndroidManifest.xml
  /// - supabase/functions/send-chat-push/worker.ts
  ///
  /// Android notification-channel behavior is effectively immutable after a
  /// channel is first created on a device. If the default behavior must change
  /// materially in the future, create a new versioned channel ID rather than
  /// silently reusing this one.
  static const String chatChannelId = 'chat_messages_v2';

  static const AndroidNotificationChannel _chatChannel =
      AndroidNotificationChannel(
    chatChannelId,
    'Chat messages',
    description: 'New direct, team, match, tournament, and club messages',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    showBadge: true,
  );

  bool _foregroundInitialized = false;
  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;

  /// Exact chat route currently visible on this device.
  ///
  /// MessageThreadScreen owns this value. It sets the ID only while its
  /// ModalRoute is current AND the app is resumed. A mounted-but-covered chat
  /// must leave this null.
  String? activeChatId;

  void setActiveChat(String? chatId) {
    if (activeChatId == chatId) return;
    activeChatId = chatId;

    debugPrint(
      '[PushMessagingService] active chat: '
      '${chatId ?? 'none'}',
    );
  }

  Future<bool> requestPermission() async {
    final settings = await _fm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    return settings.authorizationStatus ==
            AuthorizationStatus.authorized ||
        settings.authorizationStatus ==
            AuthorizationStatus.provisional;
  }

  Future<String?> getToken() => _fm.getToken();

  Stream<String> get tokenRefreshes => _fm.onTokenRefresh;

  Future<void> deleteToken() => _fm.deleteToken();

  /// Notification taps when the process already existed in the background.
  Stream<String> get tapRoutes =>
      FirebaseMessaging.onMessageOpenedApp
          .map((message) => message.data['route'])
          .where(
            (route) =>
                route is String &&
                route.trim().isNotEmpty,
          )
          .cast<String>();

  /// Notification tap that cold-started the process.
  Future<String?> initialTapRoute() async {
    final message = await _fm.getInitialMessage();
    final route = message?.data['route'];

    if (route is! String) return null;

    final normalized = route.trim();
    return normalized.isEmpty ? null : normalized;
  }

  /// Initializes local notification presentation for foreground FCM messages.
  ///
  /// Android/iOS already display notification messages while backgrounded or
  /// terminated. Foreground messages require us to present a local
  /// notification ourselves.
  Future<void> initForegroundDisplay({
    required void Function(String route) onTapRoute,
  }) async {
    if (_foregroundInitialized) return;

    try {
      final initialized = await _local.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings(
            '@mipmap/ic_launcher',
          ),
          iOS: DarwinInitializationSettings(
            defaultPresentAlert: true,
            defaultPresentBadge: true,
            defaultPresentSound: true,
            defaultPresentBanner: true,
            defaultPresentList: true,
          ),
        ),
        onDidReceiveNotificationResponse: (response) {
          final route = response.payload?.trim();
          if (route == null || route.isEmpty) return;

          try {
            onTapRoute(route);
          } catch (error, stack) {
            debugPrint(
              '[PushMessagingService] '
              'notification-tap callback failed: '
              '$error\n$stack',
            );
          }
        },
      );

      if (initialized == false) {
        throw StateError(
          'flutter_local_notifications failed to initialize',
        );
      }

      // Create the channel before any foreground local notification is posted.
      await _local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_chatChannel);

      _foregroundMessageSubscription =
          FirebaseMessaging.onMessage.listen(
        (message) {
          unawaited(_showForeground(message));
        },
        onError: (Object error, StackTrace stack) {
          debugPrint(
            '[PushMessagingService] '
            'FirebaseMessaging.onMessage stream error: '
            '$error\n$stack',
          );
        },
      );

      _foregroundInitialized = true;

      debugPrint(
        '[PushMessagingService] '
        'foreground notification surface initialized '
        'on channel $chatChannelId',
      );
    } catch (error, stack) {
      await _foregroundMessageSubscription?.cancel();
      _foregroundMessageSubscription = null;
      _foregroundInitialized = false;

      debugPrint(
        '[PushMessagingService] '
        'foreground initialization failed: '
        '$error\n$stack',
      );

      rethrow;
    }
  }

  Future<void> _showForeground(
    RemoteMessage message,
  ) async {
    try {
      final notification = message.notification;

      // Current Matchday push jobs are notification + data messages.
      if (notification == null) {
        debugPrint(
          '[PushMessagingService] '
          'foreground data-only message ignored',
        );
        return;
      }

      final incomingChatId =
          message.data['chat_id']?.toString();

      // Core product rule:
      //
      // If the exact conversation is already visible, Ably has rendered the
      // incoming message in-place. Showing a second heads-up would be noisy.
      if (incomingChatId != null &&
          incomingChatId == activeChatId) {
        debugPrint(
          '[PushMessagingService] '
          'suppressed foreground notification for visible chat '
          '$incomingChatId',
        );
        return;
      }

      final route = message.data['route'];
      final payload =
          route is String && route.trim().isNotEmpty
              ? route.trim()
              : null;

      await _local.show(
        id: _notificationId(message),
        title: notification.title,
        body: notification.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _chatChannel.id,
            _chatChannel.name,
            channelDescription: _chatChannel.description,
            importance: Importance.max,
            priority: Priority.max,
            category: AndroidNotificationCategory.message,
            playSound: true,
            enableVibration: true,
            channelShowBadge: true,
            autoCancel: true,
            icon: '@mipmap/ic_launcher',
            tag: incomingChatId == null
                ? null
                : 'chat:$incomingChatId',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBanner: true,
            presentList: true,
            presentSound: true,
            interruptionLevel: InterruptionLevel.active,
          ),
        ),
        payload: payload,
      );

      debugPrint(
        '[PushMessagingService] '
        'foreground heads-up posted'
        '${incomingChatId == null ? '' : ' for chat $incomingChatId'}',
      );
    } catch (error, stack) {
      // Notification display must never terminate messaging/the app.
      debugPrint(
        '[PushMessagingService] '
        'foreground notification display failed: '
        '$error\n$stack',
      );
    }
  }

  int _notificationId(RemoteMessage message) {
    final stableKey =
        message.messageId ??
        message.data['message_id']?.toString() ??
        '${message.sentTime?.millisecondsSinceEpoch ?? 0}:'
            '${message.data.hashCode}';

    return stableKey.hashCode & 0x7fffffff;
  }

  Future<void> dispose() async {
    await _foregroundMessageSubscription?.cancel();
    _foregroundMessageSubscription = null;
    _foregroundInitialized = false;
    activeChatId = null;
  }
}
