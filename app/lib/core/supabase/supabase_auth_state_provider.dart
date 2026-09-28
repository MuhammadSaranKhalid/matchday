import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_client_provider.dart';

export 'package:supabase_flutter/supabase_flutter.dart'
    show AuthState, AuthChangeEvent, Session, SignOutReason;
export 'supabase_current_user_id_provider.dart' show currentUserIdProvider;

part 'supabase_auth_state_provider.g.dart';

/// Stream of native Supabase [AuthState] events.
///
/// Emits [AsyncLoading] while the local session is being restored from storage,
/// then emits [AsyncData<AuthState>] for events including initialSession, signedIn,
/// signedOut, tokenRefreshed, and userUpdated.
@Riverpod(keepAlive: true)
Stream<AuthState> authState(Ref ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return supabase.auth.onAuthStateChange;
}
