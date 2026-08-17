import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/match_request.dart';
import '../repositories/matches_repository.dart';

class ListMyMatchChallengesUseCase {
  const ListMyMatchChallengesUseCase(this._repository);

  final MatchesRepository _repository;

  Future<Either<Failure, List<MatchRequest>>> call() {
    return _repository.listMyMatchChallenges();
  }
}
