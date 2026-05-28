import '../../../../core/usecase/usecase.dart';
import '../entities/match.dart';
import '../repositories/matches_repository.dart';

/// Stream of match row updates via the `match:<id>:state` broadcast channel.
class WatchMatch implements StreamUseCase<Match?, MatchId> {
  const WatchMatch(this._repo);
  final MatchesRepository _repo;

  @override
  Stream<Match?> call(MatchId id) => _repo.watchMatch(id);
}
