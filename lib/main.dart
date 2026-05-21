import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';

// Pass these via --dart-define at run/build time.
const _supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://YOUR-PROJECT.supabase.co',
);
const _supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: 'YOUR-ANON-KEY',
);
const _googleWebClientId = String.fromEnvironment(
  'GOOGLE_WEB_CLIENT_ID',
  defaultValue: '',
);
const _googleIosClientId = String.fromEnvironment(
  'GOOGLE_IOS_CLIENT_ID',
  defaultValue: '',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Supabase — PKCE flow is the v2 default; safer on mobile than implicit.
  await Supabase.initialize(
    url: _supabaseUrl,
    anonKey: _supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
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
  final clientId = kIsWeb ? _googleWebClientId : _googleIosClientId;
  final serverClientId = kIsWeb ? '' : _googleWebClientId;
  await GoogleSignIn.instance.initialize(
    serverClientId: serverClientId.isEmpty ? null : serverClientId,
    clientId: clientId.isEmpty ? null : clientId,
  );

  runApp(const ProviderScope(child: NovexApp()));
}
