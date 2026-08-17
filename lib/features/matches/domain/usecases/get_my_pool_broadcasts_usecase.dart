import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../teams/domain/entities/team.dart';
import '../entities/match_request.dart';
import '../repositories/match_pool_repository.dart';

/// Clean Architecture Use Case: Get match pool broadcasts created by user's teams.
class GetMyPoolBroadcastsUseCase {
  const GetMyPoolBroadcastsUseCase(this._repository);

  final MatchPoolRepository _repository;

  Future<Either<Failure, List<MatchRequest>>> call({
    required Set<TeamId> myTeamIds,
  }) {
    return _repository.getMyPoolBroadcasts(myTeamIds: myTeamIds);
  }
}
