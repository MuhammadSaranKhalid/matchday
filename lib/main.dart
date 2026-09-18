import 'dart:ui' show PlatformDispatcher;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart'
    show
        kIsWeb,
        LicenseRegistry,
        LicenseEntryWithLineBreaks,
        defaultTargetPlatform,
        TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'core/config/app_config.dart';
import 'firebase_options.dart';

/// Required top-level handler for FCM messages received while the app is
/// backgrounded / terminated. The OS renders the `notification` block itself,
/// and the in-app notifications broadcast re-hydrates on next open, so there is
/// nothing to do here — it exists only because FirebaseMessaging requires a
/// registered background handler to be present.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

/// Logs unhandled provider failures to the terminal so errors are never silent.
final class _AppLogObserver extends ProviderObserver {
  @override
  void providerDidFail(
    ProviderObserverContext context,
    Object error,
    StackTrace stackTrace,
  ) {
    debugPrint('[Riverpod Error] ${context.provider.name ?? context.provider.runtimeType}: $error');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Forward framework and async platform errors to console
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('[FlutterError] ${details.exceptionAsString()}');
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('[PlatformDispatcher] Unhandled error: $error\n$stack');
    return true;
  };

  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'Tabler Icons',
    ], await rootBundle.loadString('assets/notification_icons/LICENSE.tabler'));
  });

  // Extract environment variables via our centralized config class.
  final config = AppConfig.fromEnvironment();

  // 0. Firebase — needed for Cloud Messaging (push). The background handler
  //    must be registered before runApp so terminated-state messages route to
  //    it. Token registration + foreground/tap handling live in PushRegistrar.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 1. Supabase — PKCE flow is the v2 default; safer on mobile than implicit.
  // detectSessionInUriPredicate isolates OAuth deep links from non-auth deep links.
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

  // 2. Google sign-in — initialize ONCE at app boot per google_sign_in v7
  //    docs. The instance is then a singleton; data sources just call
  //    authenticate() / authorizeScopes() on it. Awaited (not fire-and-forget)
  //    so a fast tap on the sign-in button can't call authenticate() before
  //    initialize() has completed. It resolves in milliseconds.
  //
  //    Platform note: `clientId` means different things per platform.
  //    - Web  : MUST be the WEB OAuth client ID (google_sign_in_web asserts
  //             a non-null appClientId at init).
  //    - iOS  : the iOS client ID.
  //    - Android: not needed (uses serverClientId).
  //    `serverClientId` is the web client ID, used to mint backend ID tokens
  //    on mobile.
  //    On web, serverClientId is rejected outright ("not supported on Web"),
  //    so it must be null there; the web client ID goes in clientId instead.
  final clientId = kIsWeb
      ? config.googleWebClientId
      : (defaultTargetPlatform == TargetPlatform.iOS
          ? config.googleIosClientId
          : null);
  final serverClientId = kIsWeb ? '' : config.googleWebClientId;
  await GoogleSignIn.instance.initialize(
    serverClientId: serverClientId.isEmpty ? null : serverClientId,
    clientId: (clientId == null || clientId.isEmpty) ? null : clientId,
  );

  runApp(
    ProviderScope(
      observers: [
        _AppLogObserver(),
      ],
      overrides: [
        // Optionally override the provider with our initialized config instance
        appConfigProvider.overrideWithValue(config),
      ],
      child: const MatchdayApp(),
    ),
  );
}
