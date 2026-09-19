import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/team.dart';
import '../../domain/value_objects/team_name.dart';

export '../../domain/entities/team.dart' show CrestKind;

part 'team_create_state.freezed.dart';

enum TeamCreateStep { basics, identity, home, crest, review }

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
    String? logoUploadError,
    String? createdTeamId,
  }) = _TeamCreateState;

  const TeamCreateState._();

  bool get canContinueBasics => TeamName.create(name).isRight();

  String? get foundedYearError {
    final text = foundedYear?.trim() ?? '';
    if (text.isEmpty) return null;
    final year = int.tryParse(text);
    return year == null || year < 1800 || year > DateTime.now().year
        ? 'Enter a year between 1800 and ${DateTime.now().year}.'
        : null;
  }

  bool get canSubmit => canContinueBasics && canContinueHome;
  bool get hasDraft => name.trim().isNotEmpty || city.trim().isNotEmpty;
  bool get canContinueHome => city.trim().isNotEmpty;
  bool get hasCoordinates => latitude != null && longitude != null;

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

  String get combinedCity {
    final a = area.trim();
    final c = city.trim();
    if (a.isEmpty) return c;
    if (c.isEmpty) return a;
    return '$a, $c';
  }
}
