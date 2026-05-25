/// How a [GeoPlace] was obtained — useful for analytics and for deciding how
/// much to trust the coordinates.
enum PlaceSource {
  /// Picked from autocomplete and resolved via a place-details lookup.
  places,

  /// Derived from the device GPS, then reverse-geocoded for a label.
  gps,

  /// Resolved by forward-geocoding the user's typed text (no place pick, no
  /// GPS, no permission). Coordinates are approximate to the matched place.
  geocoded,

  /// Free-typed by the user; no coordinates.
  manual,
}

/// A resolved, storable location: a human label plus (usually) coordinates.
///
/// [latitude]/[longitude] may be null only for [PlaceSource.manual] entries —
/// the rare case where a player's village isn't indexed and they typed it by
/// hand. Everything else carries coordinates so proximity ("teams near you")
/// can include the player.
class GeoPlace {
  const GeoPlace({
    required this.label,
    required this.source,
    this.placeId,
    this.latitude,
    this.longitude,
    this.countryCode,
  });

  /// Free-typed fallback with no coordinates.
  factory GeoPlace.manual(String label) =>
      GeoPlace(label: label.trim(), source: PlaceSource.manual);

  final String label;
  final PlaceSource source;
  final String? placeId;
  final double? latitude;
  final double? longitude;

  /// ISO 3166-1 alpha-2, e.g. "PK".
  final String? countryCode;

  bool get hasCoordinates => latitude != null && longitude != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GeoPlace &&
          other.label == label &&
          other.source == source &&
          other.placeId == placeId &&
          other.latitude == latitude &&
          other.longitude == longitude &&
          other.countryCode == countryCode;

  @override
  int get hashCode =>
      Object.hash(label, source, placeId, latitude, longitude, countryCode);
}
