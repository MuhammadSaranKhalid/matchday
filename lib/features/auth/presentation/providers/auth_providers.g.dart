// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(authRemoteDataSource)
final authRemoteDataSourceProvider = AuthRemoteDataSourceProvider._();

final class AuthRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          AuthRemoteDataSource,
          AuthRemoteDataSource,
          AuthRemoteDataSource
        >
    with $Provider<AuthRemoteDataSource> {
  AuthRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authRemoteDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<AuthRemoteDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AuthRemoteDataSource create(Ref ref) {
    return authRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthRemoteDataSource>(value),
    );
  }
}

String _$authRemoteDataSourceHash() =>
    r'9913d41192aa8525aa5615455a5d02e74cc65336';

@ProviderFor(authRepository)
final authRepositoryProvider = AuthRepositoryProvider._();

final class AuthRepositoryProvider
    extends $FunctionalProvider<AuthRepository, AuthRepository, AuthRepository>
    with $Provider<AuthRepository> {
  AuthRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authRepositoryHash();

  @$internal
  @override
  $ProviderElement<AuthRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuthRepository create(Ref ref) {
    return authRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthRepository>(value),
    );
  }
}

String _$authRepositoryHash() => r'360ac8b7d19c65768e5bb5d875d7db55d010c8e5';

/// Stream of the current user — drives router redirects + global UI.
///
/// keepAlive: this is the app-lifetime auth session stream (a Supabase
/// realtime channel). Letting it autodispose would tear down and re-subscribe
/// the channel whenever listeners momentarily drop to zero, risking a missed
/// auth event in the gap.

@ProviderFor(currentUserStream)
final currentUserStreamProvider = CurrentUserStreamProvider._();

/// Stream of the current user — drives router redirects + global UI.
///
/// keepAlive: this is the app-lifetime auth session stream (a Supabase
/// realtime channel). Letting it autodispose would tear down and re-subscribe
/// the channel whenever listeners momentarily drop to zero, risking a missed
/// auth event in the gap.

final class CurrentUserStreamProvider
    extends $FunctionalProvider<AsyncValue<User?>, User?, Stream<User?>>
    with $FutureModifier<User?>, $StreamProvider<User?> {
  /// Stream of the current user — drives router redirects + global UI.
  ///
  /// keepAlive: this is the app-lifetime auth session stream (a Supabase
  /// realtime channel). Letting it autodispose would tear down and re-subscribe
  /// the channel whenever listeners momentarily drop to zero, risking a missed
  /// auth event in the gap.
  CurrentUserStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentUserStreamProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentUserStreamHash();

  @$internal
  @override
  $StreamProviderElement<User?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<User?> create(Ref ref) {
    return currentUserStream(ref);
  }
}

String _$currentUserStreamHash() => r'd9a4bfdc4eb448ece0dfcdc6da38dfc0ac11722c';
