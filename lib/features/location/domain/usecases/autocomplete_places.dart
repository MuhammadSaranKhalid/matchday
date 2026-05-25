import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/place_suggestion.dart';
import '../repositories/location_repository.dart';

/// Fetches autocomplete predictions. Short-circuits to an empty list (no network
/// call, no billing) until the query clears the minimum length — autocomplete on
/// one or two characters is noise and burns quota.
class AutocompletePlaces implements UseCase<List<PlaceSuggestion>, AutocompletePlacesParams> {
  const AutocompletePlaces(this._repo);
  final LocationRepository _repo;

  static const minQueryLength = 2;

  @override
  Future<Either<Failure, List<PlaceSuggestion>>> call(
    AutocompletePlacesParams p,
  ) async {
    final query = p.query.trim();
    if (query.length < minQueryLength) {
      return const Right([]);
    }
    return _repo.autocomplete(
      query,
      sessionToken: p.sessionToken,
      languageCode: p.languageCode,
      regionCode: p.regionCode,
    );
  }
}

class AutocompletePlacesParams {
  const AutocompletePlacesParams({
    required this.query,
    required this.sessionToken,
    this.languageCode,
    this.regionCode,
  });

  final String query;
  final String sessionToken;
  final String? languageCode;
  final String? regionCode;
}
