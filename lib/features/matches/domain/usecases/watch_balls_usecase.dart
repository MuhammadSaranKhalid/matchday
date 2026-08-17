import '../entities/ball.dart';
import '../entities/match.dart';
import '../repositories/matches_repository.dart';

class WatchBallsUseCase {
  const WatchBallsUseCase(this._repository);

  final MatchesRepository _repository;

  Stream<List<Ball>> call(MatchId matchId, int inningsNumber) {
    return _repository.watchBalls(matchId, inningsNumber);
  }
}
