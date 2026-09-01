import '../../domain/entities/ground.dart';

/// Wire shape for `grounds` rows and `search_grounds(...)` result rows.
///
/// Hand-rolled rather than freezed: the two shapes differ slightly (the RPC
/// flattens `city` out of the location jsonb and adds `distance_km`), and the
/// mapping is a straight read.
class GroundDto {
  const GroundDto(this._row);

  final Map<String, dynamic> _row;

  factory GroundDto.fromJson(Map<String, dynamic> json) => GroundDto(json);

  static double? _double(Object? v) =>
      v == null ? null : (v is num ? v.toDouble() : double.tryParse('$v'));

  Ground toEntity() {
    // A table read nests these under `location`; the search RPC returns
    // `city` at the top level and no coordinates.
    final loc = _row['location'];
    final location = loc is Map ? Map<String, dynamic>.from(loc) : null;

    return Ground(
      id: _row['ground_id'] as String,
      name: _row['name'] as String? ?? 'Ground',
      city: (_row['city'] ?? location?['city']) as String?,
      latitude: _double(location?['lat']),
      longitude: _double(location?['lng']),
      surface: GroundSurface.fromWire(_row['surface'] as String?),
      hasFloodlights: _row['has_floodlights'] as bool? ?? false,
      notes: _row['notes'] as String?,
      distanceKm: _double(_row['distance_km']),
    );
  }
}
