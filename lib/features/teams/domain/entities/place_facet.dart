import 'package:equatable/equatable.dart';

class PlaceFacet extends Equatable {
  const PlaceFacet({
    required this.city,
    required this.teamCount,
    this.lat,
    this.lng,
  });

  final String city;
  final double? lat;
  final double? lng;
  final int teamCount;

  bool get hasCenter => lat != null && lng != null;

  @override
  List<Object?> get props => [city, lat, lng, teamCount];
}
