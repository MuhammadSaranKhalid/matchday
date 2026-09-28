import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/team.dart';
import '../../domain/entities/team_search_result.dart';

part 'team_search_result_dto.freezed.dart';
part 'team_search_result_dto.g.dart';

@freezed
abstract class TeamSearchResultDto with _$TeamSearchResultDto {
  const factory TeamSearchResultDto({
    @JsonKey(name: 'team_id') required String teamId,
    @JsonKey(name: 'team_name') required String teamName,
    @JsonKey(name: 'logo_url') String? logoUrl,
    @JsonKey(name: 'logo_monogram') String? logoMonogram,
    @JsonKey(name: 'team_colors') Map<String, dynamic>? teamColors,
    @JsonKey(name: 'is_verified') @Default(false) bool isVerified,
    @JsonKey(name: 'distance_km') double? distanceKm,
    @JsonKey(name: 'founded_year') int? foundedYear,
    @JsonKey(name: 'team_type') String? teamType,
    @Default(0.0) double score,
  }) = _TeamSearchResultDto;

  const TeamSearchResultDto._();

  factory TeamSearchResultDto.fromJson(Map<String, dynamic> json) =>
      _$TeamSearchResultDtoFromJson(json);

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
