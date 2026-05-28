import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/match.dart';
import '../repositories/matches_repository.dart';

/// Delete the most recent delivery in (matchId, inningsNumber). The
/// server-side RPC reverses the state change the delivery caused so the
/// on-strike trio rolls back too. Returns true when a row was deleted.
class UndoLastBall implements UseCase<bool, UndoLastBallParams> {
  const UndoLastBall(this._repo);
  final MatchesRepository _repo;

  @override
  Future<Either<Failure, bool>> call(UndoLastBallParams p) =>
      _repo.undoLastBall(matchId: p.matchId, inningsNumber: p.inningsNumber);
}

class UndoLastBallParams {
  const UndoLastBallParams({
    required this.matchId,
    required this.inningsNumber,
  });

  final MatchId matchId;
  final int inningsNumber;
}
