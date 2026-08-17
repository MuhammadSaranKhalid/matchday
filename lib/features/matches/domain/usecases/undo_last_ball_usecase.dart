import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/match.dart';
import '../repositories/matches_repository.dart';

class UndoLastBallUseCase {
  const UndoLastBallUseCase(this._repository);

  final MatchesRepository _repository;

  Future<Either<Failure, bool>> call({
    required MatchId matchId,
    required int inningsNumber,
  }) {
    return _repository.undoLastBall(
      matchId: matchId,
      inningsNumber: inningsNumber,
    );
  }
}
