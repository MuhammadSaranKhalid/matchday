import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/team.dart';

part 'team_dto.freezed.dart';
part 'team_dto.g.dart';

/// Wire-format `teams` row. `location` and `team_colors` are jsonb blobs.
@freezed
abstract class TeamDto with _$TeamDto {
  const factory TeamDto({
    @JsonKey(name: 'team_id') required String teamId,
    @JsonKey(name: 'owner_id') required String ownerId,
    @JsonKey(name: 'team_name') required String teamName,
    @JsonKey(name: 'team_type') required String teamType,
    String? description,
    @JsonKey(name: 'home_ground') String? homeGround,
    Map<String, dynamic>? location,
    @JsonKey(name: 'founded_year') int? foundedYear,
    @JsonKey(name: 'team_colors') Map<String, dynamic>? teamColors,
    @Default(<String>[]) List<String> managers,
    @Default('public') String privacy,
    String? tagline,
    @JsonKey(name: 'logo_url') String? logoUrl,
    @JsonKey(name: 'logo_monogram') String? logoMonogram,
    @JsonKey(name: 'is_verified') @Default(false) bool isVerified,
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'updated_at') required String updatedAt,
  }) = _TeamDto;

  const TeamDto._();

  factory TeamDto.fromJson(Map<String, dynamic> json) =>
      _$TeamDtoFromJson(json);

  Team toEntity() => Team(
        id: TeamId(teamId),
        ownerId: ownerId,
        name: teamName,
        type: TeamType.fromWire(teamType),
        privacy: TeamPrivacy.fromWire(privacy),
        managers: managers,
        description: description,
        homeGround: homeGround,
        city: location?['city'] as String?,
        foundedYear: foundedYear,
        primaryColor: teamColors?['primary'] as String?,
        secondaryColor: teamColors?['secondary'] as String?,
        tagline: tagline,
        logoUrl: logoUrl,
        logoMonogram: logoMonogram,
        isVerified: isVerified,
        createdAt: DateTime.parse(createdAt),
        updatedAt: DateTime.parse(updatedAt),
      );
}
