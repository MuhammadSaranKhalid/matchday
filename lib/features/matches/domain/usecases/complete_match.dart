import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/match.dart';
import '../repositories/matches_repository.dart';

/// Mark a match completed with a result description.
class CompleteMatch implements UseCase<Match, CompleteMatchParams> {
  const CompleteMatch(this._repo);
  final MatchesRepository _repo;

  @override
  Future<Either<Failure, Match>> call(CompleteMatchParams p) {
    final desc = p.description.trim();
    if (desc.isEmpty) {
      return Future.value(const Left(ValidationFailure('A result is required')));
    }
    return _repo.completeMatch(id: p.id, description: desc);
  }
}

class CompleteMatchParams {
  const CompleteMatchParams({required this.id, required this.description});
  final MatchId id;
  final String description;
}
