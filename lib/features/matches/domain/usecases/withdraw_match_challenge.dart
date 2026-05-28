import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/match_request.dart';
import '../repositories/matches_repository.dart';

class WithdrawMatchChallenge
    implements UseCase<Unit, WithdrawMatchChallengeParams> {
  const WithdrawMatchChallenge(this._repo);
  final MatchesRepository _repo;

  @override
  Future<Either<Failure, Unit>> call(WithdrawMatchChallengeParams p) =>
      _repo.withdrawMatchChallenge(
        requestId: p.requestId,
        decisionNote: p.decisionNote?.trim(),
      );
}

class WithdrawMatchChallengeParams {
  const WithdrawMatchChallengeParams({
    required this.requestId,
    this.decisionNote,
  });

  final MatchRequestId requestId;
  final String? decisionNote;
}
