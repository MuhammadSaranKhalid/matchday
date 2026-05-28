import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/innings_summary.dart';
import '../entities/match.dart';
import '../repositories/matches_repository.dart';

/// Per-team innings totals (runs / wickets / balls faced) for a set of
/// matches, aggregated from the `balls` table. Used by My Matches past
/// tiles to render `181/6 v 178/10` without N+1 fan-out.
class ListInningsForMatches
    implements
        UseCase<Map<MatchId, List<InningsSummary>>,
            ListInningsForMatchesParams> {
  const ListInningsForMatches(this._repo);
  final MatchesRepository _repo;

  @override
  Future<Either<Failure, Map<MatchId, List<InningsSummary>>>> call(
    ListInningsForMatchesParams params,
  ) =>
      _repo.listInningsForMatches(params.matchIds);
}

class ListInningsForMatchesParams {
  const ListInningsForMatchesParams(this.matchIds);
  final Iterable<MatchId> matchIds;
}
