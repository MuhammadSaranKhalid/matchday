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
    extends $NotifierProvider<AuthController, AuthFlowState> {
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
  Override overrideWithValue(AuthFlowState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthFlowState>(value),
    );
  }
}

String _$authControllerHash() => r'beedbe1c5a3435c2946931046d3854c03c5adde5';

/// Auth controller for email-OTP + Google sign-in.
///
/// Notifier (not AsyncNotifier) because the initial state is synchronous
/// (AuthInitial) and the multiple sub-states of the OTP flow are better
/// represented by a sealed class than by AsyncValue.

abstract class _$AuthController extends $Notifier<AuthFlowState> {
  AuthFlowState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AuthFlowState, AuthFlowState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AuthFlowState, AuthFlowState>,
              AuthFlowState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
