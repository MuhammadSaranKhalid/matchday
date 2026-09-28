// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'supabase_current_user_id_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(currentUserId)
final currentUserIdProvider = CurrentUserIdProvider._();

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

final class CurrentUserIdProvider
    extends $FunctionalProvider<String?, String?, String?>
    with $Provider<String?> {
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
  CurrentUserIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentUserIdProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentUserIdHash();

  @$internal
  @override
  $ProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String? create(Ref ref) {
    return currentUserId(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$currentUserIdHash() => r'99c06c38453b7c1a8ba9a2e3a27f6e0f2d277f6d';
