import '../../domain/entities/geo_place.dart';

/// Wire model for a Places API (New) Place Details response (field mask
/// `id,location,displayName,addressComponents`) and for a classic Geocoding API
/// result. Hand-parsed for the same reason as [PlaceSuggestionDto] — the payload
/// is nested, not a flat row.
///
/// `city`/`district`/`province`/`postcode` are extracted from the structured
/// address components (NOT the display label) so `location.city` stores a clean
/// locality, not a full formatted address.
class GeoPlaceDto {
  const GeoPlaceDto({
    required this.label,
    this.city,
    this.district,
    this.province,
    this.postcode,
    this.placeId,
    this.latitude,
    this.longitude,
    this.countryCode,
  });

  final String label;
  final String? city;
  final String? district;
  final String? province;
  final String? postcode;
  final String? placeId;
  final double? latitude;
  final double? longitude;
  final String? countryCode;

  // Component types we treat as the "locality", in priority order. Villages
  // often carry no `locality`, so we fall back finer→coarser. Both API shapes
  // share these type strings (per Google docs); only the text accessor differs.
  static const _localityTypes = <String>[
    'locality',
    'postal_town',
    'sublocality',
    'administrative_area_level_3',
    'administrative_area_level_2',
  ];

  /// Places API (New) detail shape: `addressComponents[]` of
  /// `{ longText, shortText, types }`.
  static GeoPlaceDto fromDetailsJson(Map<String, dynamic> json) {
    final loc = json['location'] as Map<String, dynamic>?;
    final comps = json['addressComponents'] as List<dynamic>?;
    final label = (json['displayName'] as Map<String, dynamic>?)?['text']
            as String? ??
        json['formattedAddress'] as String? ??
        '';
    return GeoPlaceDto(
      label: label,
      city: _pickNew(comps, _localityTypes),
      district: _pickNew(comps, const ['administrative_area_level_2']),
      province: _pickNew(comps, const ['administrative_area_level_1']),
      postcode: _pickNew(comps, const ['postal_code']),
      placeId: json['id'] as String?,
      latitude: (loc?['latitude'] as num?)?.toDouble(),
      longitude: (loc?['longitude'] as num?)?.toDouble(),
      countryCode: _pickNew(comps, const ['country'], short: true),
    );
  }

  /// Classic Geocoding API result shape: `geometry.location` +
  /// `address_components[]` of `{ long_name, short_name, types }`. Used for
  /// forward-geocoding typed text and reverse-geocoding device GPS.
  static GeoPlaceDto fromGeocodeResult(Map<String, dynamic> json) {
    final loc = (json['geometry'] as Map<String, dynamic>?)?['location']
        as Map<String, dynamic>?;
    final comps = json['address_components'] as List<dynamic>?;
    return GeoPlaceDto(
      label: json['formatted_address'] as String? ?? '',
      city: _pickGeo(comps, _localityTypes),
      district: _pickGeo(comps, const ['administrative_area_level_2']),
      province: _pickGeo(comps, const ['administrative_area_level_1']),
      postcode: _pickGeo(comps, const ['postal_code']),
      placeId: json['place_id'] as String?,
      latitude: (loc?['lat'] as num?)?.toDouble(),
      longitude: (loc?['lng'] as num?)?.toDouble(),
      countryCode: _pickGeo(comps, const ['country'], short: true),
    );
  }

  /// First component (priority order) whose `types` contains one of [wantTypes],
  /// Places (New) shape. Returns `longText` (or `shortText` when [short], e.g.
  /// the ISO country code).
  static String? _pickNew(
    List<dynamic>? comps,
    List<String> wantTypes, {
    bool short = false,
  }) {
    if (comps == null) return null;
    for (final t in wantTypes) {
      for (final c in comps.cast<Map<String, dynamic>>()) {
        final types = (c['types'] as List<dynamic>?)?.cast<String>() ?? const [];
        if (types.contains(t)) {
          return short
              ? (c['shortText'] as String? ?? c['longText'] as String?)
              : (c['longText'] as String? ?? c['shortText'] as String?);
        }
      }
    }
    return null;
  }

  /// As [_pickNew] but for the classic Geocoding shape (`long_name`/`short_name`).
  static String? _pickGeo(
    List<dynamic>? comps,
    List<String> wantTypes, {
    bool short = false,
  }) {
    if (comps == null) return null;
    for (final t in wantTypes) {
      for (final c in comps.cast<Map<String, dynamic>>()) {
        final types = (c['types'] as List<dynamic>?)?.cast<String>() ?? const [];
        if (types.contains(t)) {
          return short
              ? (c['short_name'] as String? ?? c['long_name'] as String?)
              : (c['long_name'] as String? ?? c['short_name'] as String?);
        }
      }
    }
    return null;
  }

  GeoPlace toEntity(PlaceSource source) => GeoPlace(
        label: label,
        source: source,
        city: city,
        district: district,
        province: province,
        postcode: postcode,
        placeId: placeId,
        latitude: latitude,
        longitude: longitude,
        countryCode: countryCode,
      );
}
