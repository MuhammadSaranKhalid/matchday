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
  await GoogleSignIn.instance.initialize(
    serverClientId: _googleWebClientId.isEmpty ? null : _googleWebClientId,
    clientId: _googleIosClientId.isEmpty ? null : _googleIosClientId,
  );

  runApp(const ProviderScope(child: NovexApp()));
}
