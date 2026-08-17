import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/match_request.dart';
import '../repositories/matches_repository.dart';

class WithdrawMatchChallengeUseCase {
  const WithdrawMatchChallengeUseCase(this._repository);

  final MatchesRepository _repository;

  Future<Either<Failure, Unit>> call({
    required MatchRequestId requestId,
    String? decisionNote,
  }) {
    return _repository.withdrawMatchChallenge(
      requestId: requestId,
      decisionNote: decisionNote,
    );
  }
}
