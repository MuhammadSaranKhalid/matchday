import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Centralized configuration class for environment variables.
class AppConfig {
  final String supabaseUrl;
  final String supabaseAnonKey;
  final String googleWebClientId;
  final String googleIosClientId;

  const AppConfig({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.googleWebClientId,
    required this.googleIosClientId,
  });

  /// Factory to extract variables directly from `--dart-define`.
  factory AppConfig.fromEnvironment() {
    const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
    const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
    
    // Fail fast in development if critical keys are missing
    assert(supabaseUrl.isNotEmpty, 'SUPABASE_URL environment variable is not set');
    assert(supabaseAnonKey.isNotEmpty, 'SUPABASE_ANON_KEY environment variable is not set');

    return const AppConfig(
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
