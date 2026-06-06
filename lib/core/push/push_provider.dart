import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'push_messaging_service.dart';

part 'push_provider.g.dart';

/// App-lifetime FCM wrapper. keepAlive — one instance for the whole session.
@Riverpod(keepAlive: true)
PushMessagingService pushMessagingService(Ref ref) => PushMessagingService(
      FirebaseMessaging.instance,
      FlutterLocalNotificationsPlugin(),
    );
