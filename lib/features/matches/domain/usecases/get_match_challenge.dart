import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/match_request.dart';
import '../repositories/matches_repository.dart';

class GetMatchChallenge
    implements UseCase<MatchRequest?, MatchRequestId> {
  const GetMatchChallenge(this._repo);
  final MatchesRepository _repo;

  @override
  Future<Either<Failure, MatchRequest?>> call(MatchRequestId id) =>
      _repo.getMatchChallenge(id);
}
