import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/innings.dart';
import '../entities/match.dart';
import '../repositories/matches_repository.dart';

/// The latest innings for a match (used to open the spectator/scorer by match).
class GetCurrentInnings implements UseCase<Innings?, MatchId> {
  const GetCurrentInnings(this._repo);
  final MatchesRepository _repo;

  @override
  Future<Either<Failure, Innings?>> call(MatchId matchId) =>
      _repo.getCurrentInnings(matchId);
}
