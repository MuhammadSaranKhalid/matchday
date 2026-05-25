import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/geo_place.dart';
import '../repositories/location_repository.dart';

/// Resolves a picked suggestion to a [GeoPlace] with coordinates.
class GetPlaceDetails implements UseCase<GeoPlace, GetPlaceDetailsParams> {
  const GetPlaceDetails(this._repo);
  final LocationRepository _repo;

  @override
  Future<Either<Failure, GeoPlace>> call(GetPlaceDetailsParams p) =>
      _repo.placeDetails(p.placeId, sessionToken: p.sessionToken);
}

class GetPlaceDetailsParams {
  const GetPlaceDetailsParams({
    required this.placeId,
    required this.sessionToken,
  });

  final String placeId;
  final String sessionToken;
}
