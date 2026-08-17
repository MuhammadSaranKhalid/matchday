import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/match.dart';
import '../repositories/matches_repository.dart';

class StartMatchNowUseCase {
  const StartMatchNowUseCase(this._repository);

  final MatchesRepository _repository;

  Future<Either<Failure, Unit>> call(MatchId id) {
    return _repository.startMatchNow(id);
  }
}
