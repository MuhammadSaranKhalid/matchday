import '../../domain/entities/geo_place.dart';

/// Wire model for a Places API (New) Place Details response (field mask
/// `id,location,displayName,addressComponents`). Hand-parsed for the same
/// reason as [PlaceSuggestionDto] — the payload is nested, not a flat row.
class GeoPlaceDto {
  const GeoPlaceDto({
    required this.label,
    this.placeId,
    this.latitude,
    this.longitude,
    this.countryCode,
  });

  final String label;
  final String? placeId;
  final double? latitude;
  final double? longitude;
  final String? countryCode;

  static GeoPlaceDto fromDetailsJson(Map<String, dynamic> json) {
    final loc = json['location'] as Map<String, dynamic>?;
    final label = (json['displayName'] as Map<String, dynamic>?)?['text']
            as String? ??
        json['formattedAddress'] as String? ??
        '';
    return GeoPlaceDto(
      label: label,
      placeId: json['id'] as String?,
      latitude: (loc?['latitude'] as num?)?.toDouble(),
      longitude: (loc?['longitude'] as num?)?.toDouble(),
      countryCode: _countryFromComponents(
        json['addressComponents'] as List<dynamic>?,
      ),
    );
  }

  /// Parses one element of the classic Geocoding API `results` array (used for
  /// forward-geocoding typed text). That payload uses `geometry.location` and
  /// `address_components[].short_name`, unlike the Places (New) detail shape.
  static GeoPlaceDto fromGeocodeResult(Map<String, dynamic> json) {
    final loc = (json['geometry'] as Map<String, dynamic>?)?['location']
        as Map<String, dynamic>?;
    return GeoPlaceDto(
      label: json['formatted_address'] as String? ?? '',
      placeId: json['place_id'] as String?,
      latitude: (loc?['lat'] as num?)?.toDouble(),
      longitude: (loc?['lng'] as num?)?.toDouble(),
      countryCode: _countryFromGeocodeComponents(
        json['address_components'] as List<dynamic>?,
      ),
    );
  }

  /// `addressComponents[].types` contains "country"; `shortText` is the ISO code.
  static String? _countryFromComponents(List<dynamic>? components) {
    if (components == null) return null;
    for (final c in components.cast<Map<String, dynamic>>()) {
      final types = (c['types'] as List<dynamic>?)?.cast<String>() ?? const [];
      if (types.contains('country')) {
        return c['shortText'] as String? ?? c['longText'] as String?;
      }
    }
    return null;
  }

  static String? _countryFromGeocodeComponents(List<dynamic>? components) {
    if (components == null) return null;
    for (final c in components.cast<Map<String, dynamic>>()) {
      final types = (c['types'] as List<dynamic>?)?.cast<String>() ?? const [];
      if (types.contains('country')) {
        return c['short_name'] as String? ?? c['long_name'] as String?;
      }
    }
    return null;
  }

  GeoPlace toEntity(PlaceSource source) => GeoPlace(
        label: label,
        source: source,
        placeId: placeId,
        latitude: latitude,
        longitude: longitude,
        countryCode: countryCode,
      );
}
