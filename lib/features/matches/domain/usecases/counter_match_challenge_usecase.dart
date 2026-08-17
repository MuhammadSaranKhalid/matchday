import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/match.dart';
import '../entities/match_request.dart';
import '../repositories/matches_repository.dart';

class CounterMatchChallengeUseCase {
  const CounterMatchChallengeUseCase(this._repository);

  final MatchesRepository _repository;

  Future<Either<Failure, Unit>> call({
    required MatchRequestId requestId,
    DateTime? counteredStartTime,
    String? counteredVenue,
    MatchFormat? counteredFormat,
    int? counteredPlayersPerSide,
    String? decisionNote,
  }) {
    return _repository.counterMatchChallenge(
      requestId: requestId,
      counteredStartTime: counteredStartTime,
      counteredVenue: counteredVenue,
      counteredFormat: counteredFormat,
      counteredPlayersPerSide: counteredPlayersPerSide,
      decisionNote: decisionNote,
    );
  }
}
