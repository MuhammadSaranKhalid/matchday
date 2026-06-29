import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/place_facet.dart';

part 'place_facet_dto.freezed.dart';
part 'place_facet_dto.g.dart';

/// One row from `team-place-facets`. `lat`/`lng` are `null` when the SQL
/// `avg()` collapses (no coord-bearing team in this group); the wire side
/// already returns SQL NULL → JSON null, so no special handling needed.
@freezed
abstract class PlaceFacetDto with _$PlaceFacetDto {
  const factory PlaceFacetDto({
    required String city,
    double? lat,
    double? lng,
    @JsonKey(name: 'team_count') required int teamCount,
  }) = _PlaceFacetDto;

  const PlaceFacetDto._();

  factory PlaceFacetDto.fromJson(Map<String, dynamic> json) =>
      _$PlaceFacetDtoFromJson(json);

  PlaceFacet toEntity() => PlaceFacet(
        city: city,
        teamCount: teamCount,
        lat: lat,
        lng: lng,
      );
}
