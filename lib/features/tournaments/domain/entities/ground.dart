import 'package:meta/meta.dart';

/// What a pitch is made of. Drives the "Turf · floodlights" line the create
/// wizard shows, which used to be free text.
enum GroundSurface {
  turf('turf', 'Turf'),
  matting('matting', 'Matting'),
  concrete('concrete', 'Concrete'),
  astro('astro', 'Astro'),
  other('other', 'Other');

  const GroundSurface(this.wire, this.label);
  final String wire;
  final String label;

  static GroundSurface? fromWire(String? wire) =>
      wire == null ? null : values.where((s) => s.wire == wire).firstOrNull;
}

/// A physical place matches are played at.
///
/// Global rather than owned by one tournament: the same ground hosts many
/// cups and many friendlies, so it carries its own coordinates and facilities
/// instead of being re-typed into each tournament's venue list.
@immutable
class Ground {
  const Ground({
    required this.id,
    required this.name,
    this.city,
    this.latitude,
    this.longitude,
    this.surface,
    this.hasFloodlights = false,
    this.notes,
    this.distanceKm,
  });

  final String id;
  final String name;
  final String? city;
  final double? latitude;
  final double? longitude;
  final GroundSurface? surface;
  final bool hasFloodlights;
  final String? notes;

  /// Only populated by a proximity-aware search; null otherwise.
  final double? distanceKm;

  /// The one-line facilities summary the wizard renders under the name.
  String? get facilities {
    final bits = [
      if (surface != null) surface!.label,
      if (hasFloodlights) 'floodlights',
    ];
    if (bits.isEmpty) return notes;
    return bits.join(' · ');
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Ground && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
