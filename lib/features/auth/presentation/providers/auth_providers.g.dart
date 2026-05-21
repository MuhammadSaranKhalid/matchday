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

@ProviderFor(sendEmailOtpUseCase)
final sendEmailOtpUseCaseProvider = SendEmailOtpUseCaseProvider._();

final class SendEmailOtpUseCaseProvider
    extends $FunctionalProvider<SendEmailOtp, SendEmailOtp, SendEmailOtp>
    with $Provider<SendEmailOtp> {
  SendEmailOtpUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sendEmailOtpUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sendEmailOtpUseCaseHash();

  @$internal
  @override
  $ProviderElement<SendEmailOtp> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SendEmailOtp create(Ref ref) {
    return sendEmailOtpUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SendEmailOtp value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SendEmailOtp>(value),
    );
  }
}

String _$sendEmailOtpUseCaseHash() =>
    r'4fe2106a4209bbdc9aaa5c1c70184fb78161b80a';

@ProviderFor(verifyEmailOtpUseCase)
final verifyEmailOtpUseCaseProvider = VerifyEmailOtpUseCaseProvider._();

final class VerifyEmailOtpUseCaseProvider
    extends $FunctionalProvider<VerifyEmailOtp, VerifyEmailOtp, VerifyEmailOtp>
    with $Provider<VerifyEmailOtp> {
  VerifyEmailOtpUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'verifyEmailOtpUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$verifyEmailOtpUseCaseHash();

  @$internal
  @override
  $ProviderElement<VerifyEmailOtp> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  VerifyEmailOtp create(Ref ref) {
    return verifyEmailOtpUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VerifyEmailOtp value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VerifyEmailOtp>(value),
    );
  }
}

String _$verifyEmailOtpUseCaseHash() =>
    r'a2f9f3f7767384d66860cd338ded35278bfabe87';

@ProviderFor(signInWithGoogleUseCase)
final signInWithGoogleUseCaseProvider = SignInWithGoogleUseCaseProvider._();

final class SignInWithGoogleUseCaseProvider
    extends
        $FunctionalProvider<
          SignInWithGoogle,
          SignInWithGoogle,
          SignInWithGoogle
        >
    with $Provider<SignInWithGoogle> {
  SignInWithGoogleUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'signInWithGoogleUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$signInWithGoogleUseCaseHash();

  @$internal
  @override
  $ProviderElement<SignInWithGoogle> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SignInWithGoogle create(Ref ref) {
    return signInWithGoogleUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SignInWithGoogle value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SignInWithGoogle>(value),
    );
  }
}

String _$signInWithGoogleUseCaseHash() =>
    r'aa731494641de1e85e8b1fa8b962d14c9f83c8e5';

@ProviderFor(signOutUseCase)
final signOutUseCaseProvider = SignOutUseCaseProvider._();

final class SignOutUseCaseProvider
    extends $FunctionalProvider<SignOut, SignOut, SignOut>
    with $Provider<SignOut> {
  SignOutUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'signOutUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$signOutUseCaseHash();

  @$internal
  @override
  $ProviderElement<SignOut> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SignOut create(Ref ref) {
    return signOutUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SignOut value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SignOut>(value),
    );
  }
}

String _$signOutUseCaseHash() => r'46de716bc4b19c44ed4be107fd3aa3d8ebee79ec';

@ProviderFor(getCurrentUserUseCase)
final getCurrentUserUseCaseProvider = GetCurrentUserUseCaseProvider._();

final class GetCurrentUserUseCaseProvider
    extends $FunctionalProvider<GetCurrentUser, GetCurrentUser, GetCurrentUser>
    with $Provider<GetCurrentUser> {
  GetCurrentUserUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'getCurrentUserUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$getCurrentUserUseCaseHash();

  @$internal
  @override
  $ProviderElement<GetCurrentUser> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GetCurrentUser create(Ref ref) {
    return getCurrentUserUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetCurrentUser value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetCurrentUser>(value),
    );
  }
}

String _$getCurrentUserUseCaseHash() =>
    r'9bf1bc5181263aea6de391b963f09349741ca8d7';

@ProviderFor(watchCurrentUserUseCase)
final watchCurrentUserUseCaseProvider = WatchCurrentUserUseCaseProvider._();

final class WatchCurrentUserUseCaseProvider
    extends
        $FunctionalProvider<
          WatchCurrentUser,
          WatchCurrentUser,
          WatchCurrentUser
        >
    with $Provider<WatchCurrentUser> {
  WatchCurrentUserUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'watchCurrentUserUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$watchCurrentUserUseCaseHash();

  @$internal
  @override
  $ProviderElement<WatchCurrentUser> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  WatchCurrentUser create(Ref ref) {
    return watchCurrentUserUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WatchCurrentUser value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WatchCurrentUser>(value),
    );
  }
}

String _$watchCurrentUserUseCaseHash() =>
    r'3e4f0ec8d3a6d0079fec6a9c487493c44cfca4c1';

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

String _$currentUserStreamHash() => r'049b3400d616d1390587d23fe4d130c2a7d7f9a1';
