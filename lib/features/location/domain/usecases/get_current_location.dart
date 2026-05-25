import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/geo_place.dart';
import '../repositories/location_repository.dart';

/// Resolves the device's current location to a labelled [GeoPlace]. The "use my
/// location" fallback that guarantees coordinates when autocomplete can't find
/// the player's village.
class GetCurrentLocation implements UseCase<GeoPlace, GetCurrentLocationParams> {
  const GetCurrentLocation(this._repo);
  final LocationRepository _repo;

  @override
  Future<Either<Failure, GeoPlace>> call(GetCurrentLocationParams p) =>
      _repo.currentLocation(languageCode: p.languageCode);
}

class GetCurrentLocationParams {
  const GetCurrentLocationParams({this.languageCode});
  final String? languageCode;
}
