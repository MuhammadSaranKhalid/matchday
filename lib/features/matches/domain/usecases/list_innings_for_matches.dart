import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/innings.dart';
import '../entities/match.dart';
import '../repositories/matches_repository.dart';

/// Bulk-fetch innings for a set of matches. Used by My Matches to compose
/// per-team final scores on Past tiles without an N+1 query fan-out.
class ListInningsForMatches
    implements UseCase<Map<MatchId, List<Innings>>, ListInningsForMatchesParams> {
  const ListInningsForMatches(this._repo);
  final MatchesRepository _repo;

  @override
  Future<Either<Failure, Map<MatchId, List<Innings>>>> call(
    ListInningsForMatchesParams params,
  ) =>
      _repo.listInningsForMatches(params.matchIds);
}

class ListInningsForMatchesParams {
  const ListInningsForMatchesParams(this.matchIds);
  final Iterable<MatchId> matchIds;
}
