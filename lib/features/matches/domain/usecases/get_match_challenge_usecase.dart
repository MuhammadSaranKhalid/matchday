import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/match_request.dart';
import '../repositories/matches_repository.dart';

class GetMatchChallengeUseCase {
  const GetMatchChallengeUseCase(this._repository);

  final MatchesRepository _repository;

  Future<Either<Failure, MatchRequest?>> call(MatchRequestId requestId) {
    return _repository.getMatchChallenge(requestId);
  }
}
