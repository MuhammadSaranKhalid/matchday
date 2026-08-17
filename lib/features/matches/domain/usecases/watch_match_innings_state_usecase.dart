import '../entities/match.dart';
import '../entities/match_innings_state.dart';
import '../repositories/matches_repository.dart';

class WatchMatchInningsStateUseCase {
  const WatchMatchInningsStateUseCase(this._repository);

  final MatchesRepository _repository;

  Stream<MatchInningsState?> call({
    required MatchId matchId,
    required int inningsNumber,
  }) {
    return _repository.watchMatchInningsState(
      matchId: matchId,
      inningsNumber: inningsNumber,
    );
  }
}
