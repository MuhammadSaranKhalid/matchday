import '../../../../core/usecase/usecase.dart';
import '../entities/innings.dart';
import '../repositories/matches_repository.dart';

/// Streams an innings' live state (totals + current players).
class WatchInnings implements StreamUseCase<Innings?, InningsId> {
  const WatchInnings(this._repo);
  final MatchesRepository _repo;

  @override
  Stream<Innings?> call(InningsId inningsId) => _repo.watchInnings(inningsId);
}
