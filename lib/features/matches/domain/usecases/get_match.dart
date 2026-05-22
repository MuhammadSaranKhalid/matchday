import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/match.dart';
import '../repositories/matches_repository.dart';

/// Fetch a single match by id (null if not found / not visible).
class GetMatch implements UseCase<Match?, MatchId> {
  const GetMatch(this._repo);
  final MatchesRepository _repo;

  @override
  Future<Either<Failure, Match?>> call(MatchId id) => _repo.getMatch(id);
}
