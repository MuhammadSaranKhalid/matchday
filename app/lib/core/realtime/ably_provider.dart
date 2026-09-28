import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../supabase/supabase_auth_state_provider.dart';
import '../supabase/supabase_client_provider.dart';
import 'ably_service.dart';

part 'ably_provider.g.dart';

/// Provides the singleton [AblyService] across the application.
///
/// Watches [currentUserIdProvider] so the service is torn down and rebuilt
/// whenever the signed-in user changes (sign-out → sign-in, or account
/// switch). This ensures the Ably [clientId] always matches the current
/// Supabase identity and prevents a stale clientId/JWT mismatch.
@Riverpod(keepAlive: true)
AblyService ablyService(Ref ref) {
  // Rebuild this provider when the user ID changes.
  ref.watch(currentUserIdProvider);
  final supabase = ref.watch(supabaseClientProvider);
  final service = AblyService(supabase);
  ref.onDispose(service.dispose);
  return service;
}
