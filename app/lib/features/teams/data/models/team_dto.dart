import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/team.dart';

part 'team_dto.freezed.dart';
part 'team_dto.g.dart';

/// Wire-format `teams` row. `team_colors` is a jsonb blob.
@freezed
abstract class TeamDto with _$TeamDto {
  const factory TeamDto({
    @JsonKey(name: 'team_id') required String teamId,
    @JsonKey(name: 'created_by') String? createdBy,
    @JsonKey(name: 'team_name') required String teamName,
    @JsonKey(name: 'team_type') required String teamType,
    String? description,
    @JsonKey(name: 'home_ground') String? homeGround,
    @JsonKey(name: 'founded_year') int? foundedYear,
    @JsonKey(name: 'team_colors') Map<String, dynamic>? teamColors,
    @Default('public') String privacy,
    String? tagline,
    @JsonKey(name: 'logo_url') String? logoUrl,
    @JsonKey(name: 'logo_monogram') String? logoMonogram,
    @JsonKey(name: 'is_verified') @Default(false) bool isVerified,
    @Default('active') String status,
    @JsonKey(name: 'max_squad_size') @Default(25) int maxSquadSize,
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'updated_at') required String updatedAt,
  }) = _TeamDto;

  const TeamDto._();

  factory TeamDto.fromJson(Map<String, dynamic> json) =>
      _$TeamDtoFromJson(json);

  Team toEntity() => Team(
        id: TeamId(teamId),
        createdBy: createdBy ?? '',
        name: teamName,
        type: TeamType.fromWire(teamType),
        privacy: TeamPrivacy.fromWire(privacy),
        description: description,
        homeGround: homeGround,
        foundedYear: foundedYear,
        primaryColor: teamColors?['primary'] as String?,
        secondaryColor: teamColors?['secondary'] as String?,
        tagline: tagline,
        logoUrl: logoUrl,
        logoMonogram: logoMonogram,
        crestKind: CrestKind.fromWire(teamColors?['crest_kind'] as String?),
        isVerified: isVerified,
        status: TeamStatus.fromWire(status),
        maxSquadSize: maxSquadSize,
        createdAt: DateTime.parse(createdAt),
        updatedAt: DateTime.parse(updatedAt),
      );
}
