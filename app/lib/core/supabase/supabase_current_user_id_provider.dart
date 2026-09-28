import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'supabase_auth_state_provider.dart';
import 'supabase_client_provider.dart';

part 'supabase_current_user_id_provider.g.dart';

/// The signed-in user's ID, derived reactively from [authStateProvider].
///
/// Re-evaluates on every [AuthChangeEvent] (signedIn, signedOut,
/// tokenRefreshed, userUpdated, initialSession). Reads identity synchronously
/// from [SupabaseClient.auth.currentUser] — Supabase is the single source of
/// truth for authentication.
///
/// Use this provider (not [authStateProvider]) as the reactive dependency in
/// every user-scoped provider, because:
/// - A transient token-refresh *error* from the stream does NOT set currentUser
///   to null, so providers remain stable during network glitches.
/// - It exposes only what user-scoped providers need: a String? UID, with no
///   session metadata or auth events leaking into business logic.
///
/// Rule:
/// ```
/// Need current identity (imperative action)?  → auth.currentUser
/// Need reactive recomputation on user change?  → ref.watch(currentUserIdProvider)
/// Need session lifecycle events (router/Ably)? → authStateProvider
/// Need a fresh/valid token?                    → await auth.getSession()
/// ```
@Riverpod(keepAlive: true)
String? currentUserId(Ref ref) {
  // Establish reactive dependency on the Supabase auth lifecycle.
  ref.watch(authStateProvider);
  // Supabase is the authoritative source of truth.
  return ref.read(supabaseClientProvider).auth.currentUser?.id;
}
