import '../../../../core/usecase/usecase.dart';
import '../entities/ball.dart';
import '../entities/innings.dart';
import '../repositories/matches_repository.dart';

/// Streams an innings' deliveries (live) for the spectator + scorer screens.
class WatchBalls implements StreamUseCase<List<Ball>, InningsId> {
  const WatchBalls(this._repo);
  final MatchesRepository _repo;

  @override
  Stream<List<Ball>> call(InningsId inningsId) => _repo.watchBalls(inningsId);
}
