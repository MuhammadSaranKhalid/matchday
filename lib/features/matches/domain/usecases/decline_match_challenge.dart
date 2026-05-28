import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/match_request.dart';
import '../repositories/matches_repository.dart';

class DeclineMatchChallenge
    implements UseCase<Unit, DeclineMatchChallengeParams> {
  const DeclineMatchChallenge(this._repo);
  final MatchesRepository _repo;

  @override
  Future<Either<Failure, Unit>> call(DeclineMatchChallengeParams p) =>
      _repo.declineMatchChallenge(
        requestId: p.requestId,
        decisionNote: p.decisionNote?.trim(),
        decisionReason: p.decisionReason,
      );
}

class DeclineMatchChallengeParams {
  const DeclineMatchChallengeParams({
    required this.requestId,
    this.decisionNote,
    this.decisionReason,
  });

  final MatchRequestId requestId;
  final String? decisionNote;
  final DeclineReason? decisionReason;
}
