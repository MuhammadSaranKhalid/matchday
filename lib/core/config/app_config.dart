import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Available environment flavors.
enum AppEnvironment { dev, staging, prod }

/// Centralized configuration class for environment variables.
class AppConfig {
  final AppEnvironment environment;
  final String supabaseUrl;
  final String supabaseAnonKey;
  final String googleWebClientId;
  final String googleIosClientId;

  const AppConfig({
    required this.environment,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.googleWebClientId,
    required this.googleIosClientId,
  });

  /// Factory to extract variables directly from `--dart-define`.
  factory AppConfig.fromEnvironment() {
    final envString = const String.fromEnvironment('ENVIRONMENT', defaultValue: 'dev');
    final environment = AppEnvironment.values.firstWhere(
      (e) => e.name == envString.toLowerCase(),
      orElse: () => AppEnvironment.dev,
    );

    var supabaseUrl = const String.fromEnvironment('SUPABASE_URL');
    const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

    // Android emulator cannot access 127.0.0.1 of the host machine; it must use 10.0.2.2
    if (supabaseUrl.contains('127.0.0.1') && !kIsWeb && Platform.isAndroid) {
      supabaseUrl = supabaseUrl.replaceAll('127.0.0.1', '10.0.2.2');
    }

    // Fail fast in development if critical keys are missing
    assert(supabaseUrl.isNotEmpty, 'SUPABASE_URL environment variable is not set');
    assert(supabaseAnonKey.isNotEmpty, 'SUPABASE_ANON_KEY environment variable is not set');

    return AppConfig(
      environment: environment,
      supabaseUrl: supabaseUrl,
      supabaseAnonKey: supabaseAnonKey,
      googleWebClientId: String.fromEnvironment('GOOGLE_WEB_CLIENT_ID', defaultValue: ''),
      googleIosClientId: String.fromEnvironment('GOOGLE_IOS_CLIENT_ID', defaultValue: ''),
    );
  }
}

/// Provider for the AppConfig so it can be injected across the app.
final appConfigProvider = Provider<AppConfig>((ref) {
  return AppConfig.fromEnvironment();
});
