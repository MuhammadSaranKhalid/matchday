import 'dart:ui' show PlatformDispatcher;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show
        kIsWeb,
        LicenseEntryWithLineBreaks,
        LicenseRegistry,
        TargetPlatform,
        defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'firebase_options.dart';

/// Logs unhandled provider failures to the terminal so errors are never silent.
final class _AppLogObserver extends ProviderObserver {
  @override
  void providerDidFail(
    ProviderObserverContext context,
    Object error,
    StackTrace stackTrace,
  ) {
    debugPrint(
      '[Riverpod Error] '
      '${context.provider.name ?? context.provider.runtimeType}: $error',
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('[FlutterError] ${details.exceptionAsString()}');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('[PlatformDispatcher] Unhandled error: $error\n$stack');
    return true;
  };

  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(
      ['Tabler Icons'],
      await rootBundle.loadString(
        'assets/notification_icons/LICENSE.tabler',
      ),
    );
  });

  final config = AppConfig.fromEnvironment();

  // Matchday uses normal FCM notification+data messages.
  //
  // Background/terminated notification presentation is owned by the OS.
  // Matchday currently performs no Dart-side background message processing,
  // so no FirebaseMessaging.onBackgroundMessage isolate is registered.
  //
  // Taps are handled later by PushMessagingService through:
  // - FirebaseMessaging.onMessageOpenedApp
  // - FirebaseMessaging.getInitialMessage()
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Supabase.initialize(
    url: config.supabaseUrl,
    publishableKey: config.supabasePublishableKey,
    authOptions: FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
      detectSessionInUriPredicate: kIsWeb
          ? null
          : (uri) =>
              uri.scheme == 'com.joinmatchday.app' &&
              uri.host == 'login-callback',
    ),
  );

  final clientId = kIsWeb
      ? config.googleWebClientId
      : (defaultTargetPlatform == TargetPlatform.iOS
          ? config.googleIosClientId
          : null);

  final serverClientId = kIsWeb ? '' : config.googleWebClientId;

  await GoogleSignIn.instance.initialize(
    serverClientId:
        serverClientId.isEmpty ? null : serverClientId,
    clientId:
        (clientId == null || clientId.isEmpty) ? null : clientId,
  );

  runApp(
    ProviderScope(
      observers: [
        _AppLogObserver(),
      ],
      overrides: [
        appConfigProvider.overrideWithValue(config),
      ],
      child: const MatchdayApp(),
    ),
  );
}
