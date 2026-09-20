import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../teams/domain/entities/team.dart';
import '../../../teams/domain/entities/team_search_result.dart';

part 'team_result_dto.freezed.dart';
part 'team_result_dto.g.dart';

/// One row from `search-all`'s team group.
///
/// Explore owns this wire shape even though `teams` has a near-identical
/// [TeamSearchResultDto], because CLAUDE.md §6.6 forbids reaching into
/// another feature's `data/` layer. Only the Domain→Domain seam is open, so
/// this maps to teams' [TeamSearchResult] entity — the entity is shared, the
/// DTO is not.
///
/// The duplication is real but deliberate: it is what keeps `search-all` and
/// `search-teams` free to diverge (they already do — `search-all` selects
/// founded_year and team_type; `search-teams` selects distance).
@freezed
abstract class TeamResultDto with _$TeamResultDto {
  const factory TeamResultDto({
    @JsonKey(name: 'team_id') required String teamId,
    @JsonKey(name: 'team_name') required String teamName,
    @JsonKey(name: 'logo_url') String? logoUrl,
    @JsonKey(name: 'logo_monogram') String? logoMonogram,
    @JsonKey(name: 'team_colors') Map<String, dynamic>? teamColors,
    Map<String, dynamic>? location,
    @JsonKey(name: 'is_verified') @Default(false) bool isVerified,
    @JsonKey(name: 'founded_year') int? foundedYear,
    @JsonKey(name: 'team_type') String? teamType,
    // Always null in v1 — no coordinates are captured yet. Kept so the
    // response shape does not change when proximity ranking lands.
    @JsonKey(name: 'distance_km') double? distanceKm,
    @Default(0.0) double score,
  }) = _TeamResultDto;

  const TeamResultDto._();

  factory TeamResultDto.fromJson(Map<String, dynamic> json) =>
      _$TeamResultDtoFromJson(json);

  TeamSearchResult toEntity() => TeamSearchResult(
        teamId: TeamId(teamId),
        name: teamName,
        score: score,
        logoUrl: logoUrl,
        logoMonogram: logoMonogram,
        primaryColor: teamColors?['primary'] as String?,
        secondaryColor: teamColors?['secondary'] as String?,
        isVerified: isVerified,
        distanceKm: distanceKm,
        foundedYear: foundedYear,
        teamType: teamType,
      );
}
