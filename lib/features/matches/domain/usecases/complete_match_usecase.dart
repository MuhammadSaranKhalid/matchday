import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/match.dart';
import '../repositories/matches_repository.dart';

class CompleteMatchUseCase {
  const CompleteMatchUseCase(this._repository);

  final MatchesRepository _repository;

  Future<Either<Failure, Match>> call({
    required MatchId id,
    required String description,
  }) {
    return _repository.completeMatch(
      id: id,
      description: description,
    );
  }
}
