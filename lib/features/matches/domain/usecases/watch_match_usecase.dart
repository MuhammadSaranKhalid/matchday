import '../entities/match.dart';
import '../repositories/matches_repository.dart';

class WatchMatchUseCase {
  const WatchMatchUseCase(this._repository);

  final MatchesRepository _repository;

  Stream<Match?> call(MatchId id) {
    return _repository.watchMatch(id);
  }
}
