// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'supabase_auth_state_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Stream of native Supabase [AuthState] events.
///
/// Emits [AsyncLoading] while the local session is being restored from storage,
/// then emits [AsyncData<AuthState>] for events including initialSession, signedIn,
/// signedOut, tokenRefreshed, and userUpdated.

@ProviderFor(authState)
final authStateProvider = AuthStateProvider._();

/// Stream of native Supabase [AuthState] events.
///
/// Emits [AsyncLoading] while the local session is being restored from storage,
/// then emits [AsyncData<AuthState>] for events including initialSession, signedIn,
/// signedOut, tokenRefreshed, and userUpdated.

final class AuthStateProvider
    extends
        $FunctionalProvider<AsyncValue<AuthState>, AuthState, Stream<AuthState>>
    with $FutureModifier<AuthState>, $StreamProvider<AuthState> {
  /// Stream of native Supabase [AuthState] events.
  ///
  /// Emits [AsyncLoading] while the local session is being restored from storage,
  /// then emits [AsyncData<AuthState>] for events including initialSession, signedIn,
  /// signedOut, tokenRefreshed, and userUpdated.
  AuthStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authStateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authStateHash();

  @$internal
  @override
  $StreamProviderElement<AuthState> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<AuthState> create(Ref ref) {
    return authState(ref);
  }
}

String _$authStateHash() => r'b348cad6428b25ee64dae313b92ed345a8262561';
