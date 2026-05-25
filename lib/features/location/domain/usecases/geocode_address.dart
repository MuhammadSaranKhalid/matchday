import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/geo_place.dart';
import '../repositories/location_repository.dart';

/// Resolves typed text to coordinates without a place pick or GPS (and so
/// without any location permission). Used to satisfy the "every profile has
/// coordinates" rule for users who type a city instead of selecting one.
class GeocodeAddress implements UseCase<GeoPlace, GeocodeAddressParams> {
  const GeocodeAddress(this._repo);
  final LocationRepository _repo;

  @override
  Future<Either<Failure, GeoPlace>> call(GeocodeAddressParams p) async {
    final query = p.query.trim();
    if (query.isEmpty) {
      return const Left(ValidationFailure('Enter a place to locate'));
    }
    return _repo.geocode(
      query,
      languageCode: p.languageCode,
      regionCode: p.regionCode,
    );
  }
}

class GeocodeAddressParams {
  const GeocodeAddressParams({
    required this.query,
    this.languageCode,
    this.regionCode,
  });

  final String query;
  final String? languageCode;
  final String? regionCode;
}
