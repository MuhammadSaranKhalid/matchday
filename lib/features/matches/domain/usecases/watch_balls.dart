import '../../../../core/usecase/usecase.dart';
import '../entities/ball.dart';
import '../entities/match.dart';
import '../repositories/matches_repository.dart';

/// Live deliveries for (match, innings). Subscribes to the broadcast
/// channel `match:<id>:balls` (per migration 0810) and emits the full
/// list filtered to this innings, oldest-first.
class WatchBalls implements StreamUseCase<List<Ball>, WatchBallsParams> {
  const WatchBalls(this._repo);
  final MatchesRepository _repo;

  @override
  Stream<List<Ball>> call(WatchBallsParams p) =>
      _repo.watchBalls(p.matchId, p.inningsNumber);
}

class WatchBallsParams {
  const WatchBallsParams({required this.matchId, required this.inningsNumber});
  final MatchId matchId;
  final int inningsNumber;
}
