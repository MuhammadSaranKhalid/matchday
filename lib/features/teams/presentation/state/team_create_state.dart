import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/team.dart';
import '../../domain/value_objects/team_name.dart';

part 'team_create_state.freezed.dart';

/// The 5 steps of the team-create wizard.
enum TeamCreateStep { basics, identity, home, crest, review }

/// How the team's crest renders. `upload` means the user provided their own
/// logo (path stored in [TeamCreateState.logoUrl]); the other three are
/// auto-generated from the team's primary color + monogram.
enum CrestKind { monogram, initials, shield, upload }

/// In-progress team-create form state. Freezed data class (same rationale as
/// OnboardingState — concurrent fields + copyWith).
@freezed
abstract class TeamCreateState with _$TeamCreateState {
  const factory TeamCreateState({
    @Default(TeamCreateStep.basics) TeamCreateStep step,
    @Default('') String name,
    @Default(TeamType.club) TeamType type,
    @Default(TeamPrivacy.public) TeamPrivacy privacy,
    @Default('') String tagline,
    String? foundedYear,
    @Default('') String city,
    @Default('') String area,
    // Structured geo resolved by the place picker. Populated when the creator
    // picks a prediction or uses GPS; all null when they keep typed text, in
    // which case the team is name-findable but not proximity-findable.
    String? locationLabel,
    String? district,
    String? province,
    String? postcode,
    String? placeId,
    double? latitude,
    double? longitude,
    String? countryCode,
    @Default('') String homeGround,
    @Default('#338946') String primaryColor,
    @Default('#FDFAF4') String secondaryColor,
    @Default(CrestKind.monogram) CrestKind crestKind,
    String? monogramOverride,
    String? logoUrl,
    String? logoName,
    int? logoSize,
    @Default(false) bool submitting,
    String? submitError,
    String? createdTeamId,
  }) = _TeamCreateState;

  const TeamCreateState._();

  bool get canContinueBasics => TeamName.create(name).isRight();
  bool get canContinueHome => city.trim().isNotEmpty;

  /// True once the team carries a real coordinate — the thing that makes it
  /// discoverable by distance.
  bool get hasCoordinates => latitude != null && longitude != null;

  /// 1–3 character crest monogram. User override wins (honoured as typed,
  /// up to the input field's maxLength); otherwise auto-derived from the
  /// first letters of the first two words of [name].
  String get monogram {
    final override = monogramOverride?.trim();
    if (override != null && override.isNotEmpty) {
      return override.toUpperCase();
    }
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    if (words.isEmpty) return '–';
    if (words.length == 1) {
      final w = words.first;
      return (w.length >= 2 ? w.substring(0, 2) : w).toUpperCase();
    }
    return (words.first[0] + words.elementAt(1)[0]).toUpperCase();
  }

  /// Combined "Area, City" for storage in the single `city` field.
  String get combinedCity {
    final a = area.trim();
    final c = city.trim();
    if (a.isEmpty) return c;
    if (c.isEmpty) return a;
    return '$a, $c';
  }
}
