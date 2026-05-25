import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../location/domain/entities/place_suggestion.dart';
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
    // Structured geo for the chosen location. Null when the user hand-typed a
    // place that couldn't be resolved (the rare uncovered-village case).
    String? placeId,
    double? lat,
    double? lng,
    String? countryCode,
    // Transient autocomplete UI state (not persisted in the draft).
    @Default(<PlaceSuggestion>[]) List<PlaceSuggestion> citySuggestions,
    @Default(false) bool citySearching,
    @Default(false) bool locating,
    @Default(false) bool resolvingLocation,
    String? cityError,
    String? citySessionToken,
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

  /// Whether the chosen location already has resolved coordinates — true after
  /// a suggestion pick or GPS. A hand-typed string alone does not qualify; it
  /// gets coordinates by forward-geocoding when the user taps Continue.
  bool get hasResolvedLocation => lat != null && lng != null;

  /// Profile step is satisfiable once the name passes its value-object rule, a
  /// non-empty city is present, and the username is confirmed available.
  /// Coordinates are NOT required here: a typed city is resolved (forward-
  /// geocoded) when the user taps Continue, so the button stays tappable while
  /// the "every profile has coordinates" guarantee is enforced in
  /// [OnboardingController.continueToPlayer] instead.
  bool get canContinueProfile =>
      DisplayName.create(displayName).isRight() &&
      City.create(city).isRight() &&
      usernameStatus == UsernameStatus.available;

  PlayerProfile get playerProfile => PlayerProfile(
        role: role,
        battingStyle: battingStyle,
        bowlingStyle: bowlingStyle,
        preferredBallTypes: preferredBall == null ? const [] : [preferredBall!],
      );
}
