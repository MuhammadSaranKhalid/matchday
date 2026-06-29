import 'package:equatable/equatable.dart';

/// One entry in the place-filter chip row, produced by `team-place-facets`.
///
/// The chip's [lat]/[lng] are the AVERAGE of the matching teams' coordinates
/// — a coarse centroid, not a Google Places geocode. That's intentional:
/// proximity ranking against the centroid is fine, and the average is free
/// (one aggregate per group). Teams without coordinates contribute null to
/// the average, so the value reflects only the coord-bearing teams in the
/// city.
class PlaceFacet extends Equatable {
  const PlaceFacet({
    required this.city,
    required this.teamCount,
    this.lat,
    this.lng,
  });

  /// The locality string the chip displays. With the §8.0 locality fix this
  /// is a canonical city/town; legacy pre-fix rows may carry a full address
  /// until they self-clean (D8).
  final String city;

  /// Centroid lat — average of the (lat,lng) of teams in this facet. Null
  /// when none of the matching teams has a coordinate yet (e.g. legacy
  /// pre-backfill cities).
  final double? lat;
  final double? lng;

  /// Active+public teams in this city. The chip shows it as `"Lahore (42)"`.
  final int teamCount;

  bool get hasCenter => lat != null && lng != null;

  @override
  List<Object?> get props => [city, lat, lng, teamCount];
}
