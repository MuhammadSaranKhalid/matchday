import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/ball.dart';
import '../repositories/matches_repository.dart';

/// Persist one delivery via the `record_ball` RPC. The RPC also performs
/// the strike rotation + end-of-over swap on the match row, so the client
/// doesn't have to mirror that logic.
class RecordBall implements UseCase<Ball, BallDraft> {
  const RecordBall(this._repo);
  final MatchesRepository _repo;

  @override
  Future<Either<Failure, Ball>> call(BallDraft draft) {
    // Cricket invariants the server also checks, but failing fast on the
    // client gives a clean ValidationFailure rather than a Postgres error.
    if (draft.isWicket && draft.wicketType == null) {
      return Future.value(const Left(
        ValidationFailure('A wicket needs a wicket type'),
      ));
    }
    if (draft.runsScored < 0 || draft.extras < 0) {
      return Future.value(const Left(
        ValidationFailure('Runs and extras must be non-negative'),
      ));
    }
    // Bye / leg-bye: runs go to extras, not the batter.
    if ((draft.ballKind == BallKind.bye ||
            draft.ballKind == BallKind.legBye) &&
        draft.runsScored != 0) {
      return Future.value(const Left(
        ValidationFailure('Bye / leg-bye runs belong in extras'),
      ));
    }
    return _repo.recordBall(draft);
  }
}
