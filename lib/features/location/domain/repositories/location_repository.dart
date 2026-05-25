import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/geo_place.dart';
import '../entities/place_suggestion.dart';

/// Place search + device geolocation. Online for autocomplete/details (Google
/// Places API New) and reverse-geocoding; uses the device GPS for
/// [currentLocation]. No offline support.
abstract class LocationRepository {
  /// Type-ahead predictions for [query], biased (not restricted) to the user's
  /// region so the app stays global. [sessionToken] groups the keystrokes of a
  /// single search with the eventual [placeDetails] call for session billing.
  Future<Either<Failure, List<PlaceSuggestion>>> autocomplete(
    String query, {
    required String sessionToken,
    String? languageCode,
    String? regionCode,
  });

  /// Resolves a picked suggestion to coordinates. Pass the same [sessionToken]
  /// used for the autocomplete keystrokes to close the billing session.
  Future<Either<Failure, GeoPlace>> placeDetails(
    String placeId, {
    required String sessionToken,
  });

  /// Reads the device GPS (requesting permission if needed) and reverse-geocodes
  /// it to a labelled [GeoPlace] with [PlaceSource.gps]. This is the fallback
  /// that guarantees coordinates for players whose village autocomplete misses.
  Future<Either<Failure, GeoPlace>> currentLocation({String? languageCode});

  /// Forward-geocodes typed text to a [GeoPlace] with [PlaceSource.geocoded].
  /// Permission-free — lets a hand-typed city resolve coordinates without a
  /// place pick or GPS. Returns a [NotFoundFailure] when nothing matches.
  Future<Either<Failure, GeoPlace>> geocode(
    String query, {
    String? languageCode,
    String? regionCode,
  });
}
