import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/match.dart';
import '../repositories/matches_repository.dart';

class GetMatchUseCase {
  const GetMatchUseCase(this._repository);

  final MatchesRepository _repository;

  Future<Either<Failure, Match?>> call(MatchId id) {
    return _repository.getMatch(id);
  }
}
