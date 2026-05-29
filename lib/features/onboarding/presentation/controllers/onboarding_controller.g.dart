// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Drives the onboarding wizard: profile → player → welcome.
///
/// An [AsyncNotifier] so [build] can restore a persisted draft before the form
/// seeds. Once loaded, sub-states (username checking, submitting) live as
/// fields on [OnboardingState] rather than flipping the [AsyncValue] to
/// loading, so the form never disappears mid-edit.

@ProviderFor(OnboardingController)
final onboardingControllerProvider = OnboardingControllerProvider._();

/// Drives the onboarding wizard: profile → player → welcome.
///
/// An [AsyncNotifier] so [build] can restore a persisted draft before the form
/// seeds. Once loaded, sub-states (username checking, submitting) live as
/// fields on [OnboardingState] rather than flipping the [AsyncValue] to
/// loading, so the form never disappears mid-edit.
final class OnboardingControllerProvider
    extends $AsyncNotifierProvider<OnboardingController, OnboardingState> {
  /// Drives the onboarding wizard: profile → player → welcome.
  ///
  /// An [AsyncNotifier] so [build] can restore a persisted draft before the form
  /// seeds. Once loaded, sub-states (username checking, submitting) live as
  /// fields on [OnboardingState] rather than flipping the [AsyncValue] to
  /// loading, so the form never disappears mid-edit.
  OnboardingControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'onboardingControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$onboardingControllerHash();

  @$internal
  @override
  OnboardingController create() => OnboardingController();
}

String _$onboardingControllerHash() =>
    r'c0ad5a6cab64f13942912b134029bb4f15fb7e74';

/// Drives the onboarding wizard: profile → player → welcome.
///
/// An [AsyncNotifier] so [build] can restore a persisted draft before the form
/// seeds. Once loaded, sub-states (username checking, submitting) live as
/// fields on [OnboardingState] rather than flipping the [AsyncValue] to
/// loading, so the form never disappears mid-edit.

abstract class _$OnboardingController extends $AsyncNotifier<OnboardingState> {
  FutureOr<OnboardingState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<OnboardingState>, OnboardingState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<OnboardingState>, OnboardingState>,
              AsyncValue<OnboardingState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
