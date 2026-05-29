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
///
/// Step-scoped fields live on per-step slices ([ProfileSlice], [PlayerSlice])
/// so each step widget can `ref.watch(...select((s) => s.profile))` and skip
/// unrelated rebuilds; cross-cutting flags ([step], [submitting], etc.) stay
/// here. The persisted draft schema is intentionally still flat — see
/// `_toDraft` / `_fromDraft` on the controller.
@freezed
abstract class OnboardingState with _$OnboardingState {
  const factory OnboardingState({
    @Default(OnboardingStep.profile) OnboardingStep step,
    @Default(ProfileSlice()) ProfileSlice profile,
    @Default(PlayerSlice()) PlayerSlice player,
    @Default(false) bool submitting,
    String? submitError,
    @Default(false) bool completed,
  }) = _OnboardingState;

  const OnboardingState._();

  /// Profile step is satisfiable once the name passes its value-object rule, a
  /// non-empty city is present, and the username is confirmed available.
  /// Coordinates are NOT required here: a typed city is resolved (forward-
  /// geocoded) when the user taps Continue, so the button stays tappable while
  /// the "every profile has coordinates" guarantee is enforced in
  /// [OnboardingController.continueToPlayer] instead.
  bool get canContinueProfile => profile.isValid;

  PlayerProfile get playerProfile => player.toPlayerProfile();
}

/// Profile-step slice: identity + location + the transient autocomplete /
/// availability-check UI flags that drive that step's widgets.
@freezed
abstract class ProfileSlice with _$ProfileSlice {
  const factory ProfileSlice({
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
    @Default(UsernameStatus.idle) UsernameStatus usernameStatus,
    String? usernameMessage,
  }) = _ProfileSlice;

  const ProfileSlice._();

  /// Whether the chosen location already has resolved coordinates — true after
  /// a suggestion pick or GPS. A hand-typed string alone does not qualify; it
  /// gets coordinates by forward-geocoding when the user taps Continue.
  bool get hasResolvedLocation => lat != null && lng != null;

  bool get isValid =>
      DisplayName.create(displayName).isRight() &&
      City.create(city).isRight() &&
      usernameStatus == UsernameStatus.available;
}

/// Player-step slice: optional cricketing self-description. Skipped users
/// submit with this slice in its default (all-null) state.
@freezed
abstract class PlayerSlice with _$PlayerSlice {
  const factory PlayerSlice({
    @Default(false) bool isPlayer,
    PlayerRole? role,
    BattingStyle? battingStyle,
    BowlingStyle? bowlingStyle,
    BallType? preferredBall,
  }) = _PlayerSlice;

  const PlayerSlice._();

  PlayerProfile toPlayerProfile() => PlayerProfile(
        role: role,
        battingStyle: battingStyle,
        bowlingStyle: bowlingStyle,
        preferredBallTypes: preferredBall == null ? const [] : [preferredBall!],
      );
}
