import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/match.dart';
import '../repositories/matches_repository.dart';

class StartInningsUseCase {
  const StartInningsUseCase(this._repository);

  final MatchesRepository _repository;

  Future<Either<Failure, Unit>> call({
    required MatchId matchId,
    required int inningsNumber,
    required String strikerId,
    required String nonStrikerId,
    required String bowlerId,
    int? target,
  }) {
    return _repository.startInnings(
      matchId: matchId,
      inningsNumber: inningsNumber,
      strikerId: strikerId,
      nonStrikerId: nonStrikerId,
      bowlerId: bowlerId,
      target: target,
    );
  }
}
