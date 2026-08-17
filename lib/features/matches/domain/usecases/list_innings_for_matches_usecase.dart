import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/innings_summary.dart';
import '../entities/match.dart';
import '../repositories/matches_repository.dart';

class ListInningsForMatchesUseCase {
  const ListInningsForMatchesUseCase(this._repository);

  final MatchesRepository _repository;

  Future<Either<Failure, Map<MatchId, List<InningsSummary>>>> call(
    Iterable<MatchId> matchIds,
  ) {
    return _repository.listInningsForMatches(matchIds);
  }
}
