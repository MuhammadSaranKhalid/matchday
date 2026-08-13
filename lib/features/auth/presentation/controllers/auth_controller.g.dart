// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Auth controller for email-OTP + Google sign-in.
///
/// Notifier (not AsyncNotifier) because the initial state is synchronous
/// (AuthInitial) and the multiple sub-states of the OTP flow are better
/// represented by a sealed class than by AsyncValue.

@ProviderFor(AuthController)
final authControllerProvider = AuthControllerProvider._();

/// Auth controller for email-OTP + Google sign-in.
///
/// Notifier (not AsyncNotifier) because the initial state is synchronous
/// (AuthInitial) and the multiple sub-states of the OTP flow are better
/// represented by a sealed class than by AsyncValue.
final class AuthControllerProvider
    extends $NotifierProvider<AuthController, AuthState> {
  /// Auth controller for email-OTP + Google sign-in.
  ///
  /// Notifier (not AsyncNotifier) because the initial state is synchronous
  /// (AuthInitial) and the multiple sub-states of the OTP flow are better
  /// represented by a sealed class than by AsyncValue.
  AuthControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authControllerHash();

  @$internal
  @override
  AuthController create() => AuthController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthState>(value),
    );
  }
}

String _$authControllerHash() => r'd6bca445b49fd14ec4331cbd4fe8f709297318b7';

/// Auth controller for email-OTP + Google sign-in.
///
/// Notifier (not AsyncNotifier) because the initial state is synchronous
/// (AuthInitial) and the multiple sub-states of the OTP flow are better
/// represented by a sealed class than by AsyncValue.

abstract class _$AuthController extends $Notifier<AuthState> {
  AuthState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AuthState, AuthState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AuthState, AuthState>,
              AuthState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
