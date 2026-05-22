import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/team.dart';
import '../../domain/value_objects/team_name.dart';

part 'team_create_state.freezed.dart';

/// The 5 steps of the team-create wizard.
enum TeamCreateStep { basics, identity, home, crest, review }

/// In-progress team-create form state. Freezed data class (same rationale as
/// OnboardingState — concurrent fields + copyWith).
@freezed
abstract class TeamCreateState with _$TeamCreateState {
  const factory TeamCreateState({
    @Default(TeamCreateStep.basics) TeamCreateStep step,
    @Default('') String name,
    @Default(TeamType.club) TeamType type,
    @Default(TeamPrivacy.public) TeamPrivacy privacy,
    String? foundedYear,
    @Default('') String city,
    @Default('') String area,
    @Default('') String homeGround,
    @Default('#338946') String primaryColor,
    @Default('#E24A3F') String secondaryColor,
    @Default(false) bool submitting,
    String? submitError,
    String? createdTeamId,
  }) = _TeamCreateState;

  const TeamCreateState._();

  bool get canContinueBasics => TeamName.create(name).isRight();
  bool get canContinueHome => city.trim().isNotEmpty;

  /// Two-letter crest monogram derived from the name.
  String get monogram {
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
