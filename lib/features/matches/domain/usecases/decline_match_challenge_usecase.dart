import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/match_request.dart';
import '../repositories/matches_repository.dart';

class DeclineMatchChallengeUseCase {
  const DeclineMatchChallengeUseCase(this._repository);

  final MatchesRepository _repository;

  Future<Either<Failure, Unit>> call({
    required MatchRequestId requestId,
    String? decisionNote,
    DeclineReason? decisionReason,
  }) {
    return _repository.declineMatchChallenge(
      requestId: requestId,
      decisionNote: decisionNote,
      decisionReason: decisionReason,
    );
  }
}
