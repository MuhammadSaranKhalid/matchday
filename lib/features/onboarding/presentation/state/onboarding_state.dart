import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../profile/domain/value_objects/display_name.dart';

part 'onboarding_state.freezed.dart';

/// Which step of the wizard is showing. Sign-in + OTP are handled upstream by
/// the auth feature, so onboarding proper is just these three.
enum OnboardingStep { identity, username, welcome }

/// Live status of the username availability check.
enum UsernameStatus { idle, checking, available, taken, invalid }

/// In-progress onboarding form state.
@freezed
abstract class OnboardingState with _$OnboardingState {
  const factory OnboardingState({
    @Default(OnboardingStep.identity) OnboardingStep step,

    // Identity fields
    @Default('') String displayName,
    String? avatarPath, // Local file path selected via image_picker
    // Google can provide a photo before the user has selected a local file.
    // The local file, when present, always takes precedence.
    String? remoteAvatarUrl,

    // Username fields
    @Default('') String username,
    @Default(UsernameStatus.idle) UsernameStatus usernameStatus,
    String? usernameMessage,

    // Form fields
    @Default(false) bool submitting,
    String? submitError,
    @Default(false) bool completed,
  }) = _OnboardingState;

  const OnboardingState._();

  /// Identity step is satisfiable once the display name passes its value-object rule.
  bool get canContinueIdentity => DisplayName.create(displayName).isRight();

  /// Username step is satisfiable once the username is confirmed available.
  bool get canSubmitUsername => usernameStatus == UsernameStatus.available;
}
