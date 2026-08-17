import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/ball.dart';
import '../repositories/matches_repository.dart';

class RecordBallUseCase {
  const RecordBallUseCase(this._repository);

  final MatchesRepository _repository;

  Future<Either<Failure, Ball>> call(BallDraft draft) {
    return _repository.recordBall(draft);
  }
}
