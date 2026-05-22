import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/team.dart';
import '../repositories/teams_repository.dart';

/// One-shot fetch of a single team from local cache.
class GetTeam implements UseCase<Team?, TeamId> {
  const GetTeam(this._repo);
  final TeamsRepository _repo;

  @override
  Future<Either<Failure, Team?>> call(TeamId id) => _repo.getTeam(id);
}
