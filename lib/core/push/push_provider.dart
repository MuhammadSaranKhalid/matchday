import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'push_messaging_service.dart';

part 'push_provider.g.dart';

/// Single app-lifetime FCM/local-notification service.
@Riverpod(keepAlive: true)
PushMessagingService pushMessagingService(Ref ref) {
  final service = PushMessagingService(
    FirebaseMessaging.instance,
    FlutterLocalNotificationsPlugin(),
  );

  ref.onDispose(() {
    unawaited(service.dispose());
  });

  return service;
}
