import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/match.dart';
import '../repositories/matches_repository.dart';

class SubmitMatchOpenersUseCase {
  const SubmitMatchOpenersUseCase(this._repository);

  final MatchesRepository _repository;

  Future<Either<Failure, Unit>> call({
    required MatchId id,
    required String strikerId,
    required String nonStrikerId,
  }) {
    return _repository.submitMatchOpeners(
      id: id,
      strikerId: strikerId,
      nonStrikerId: nonStrikerId,
    );
  }
}
