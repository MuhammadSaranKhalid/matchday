import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/player_profile.dart';
import '../../domain/value_objects/city.dart';
import '../../domain/value_objects/display_name.dart';

part 'onboarding_state.freezed.dart';

/// Which step of the wizard is showing. Sign-in + OTP are handled upstream by
/// the auth feature, so onboarding proper is just these three.
enum OnboardingStep { profile, player, welcome }

/// Live status of the username availability check.
enum UsernameStatus { idle, checking, available, taken, invalid }

/// In-progress onboarding form state. A freezed data class (not a sealed
/// union) because every field coexists and mutates independently — the classic
/// "complex form state with copyWith" case from CLAUDE.md §6.3.
@freezed
abstract class OnboardingState with _$OnboardingState {
  const factory OnboardingState({
    @Default(OnboardingStep.profile) OnboardingStep step,
    @Default('') String displayName,
    @Default('') String username,
    @Default('') String city,
    @Default(false) bool isPlayer,
    PlayerRole? role,
    BattingStyle? battingStyle,
    BowlingStyle? bowlingStyle,
    BallType? preferredBall,
    @Default(UsernameStatus.idle) UsernameStatus usernameStatus,
    String? usernameMessage,
    @Default(false) bool submitting,
    String? submitError,
    @Default(false) bool completed,
  }) = _OnboardingState;

  const OnboardingState._();

  /// Profile step is satisfiable once the name and city pass their value-object
  /// rules and the username is confirmed available. Delegating to the value
  /// objects keeps the rules in one place.
  bool get canContinueProfile =>
      DisplayName.create(displayName).isRight() &&
      City.create(city).isRight() &&
      usernameStatus == UsernameStatus.available;

  PlayerProfile get playerProfile => PlayerProfile(
        role: role,
        battingStyle: battingStyle,
        bowlingStyle: bowlingStyle,
        preferredBall: preferredBall,
      );
}
