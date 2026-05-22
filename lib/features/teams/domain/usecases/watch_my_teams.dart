import '../../../../core/usecase/usecase.dart';
import '../entities/team.dart';
import '../repositories/teams_repository.dart';

/// Streams the teams the given user owns or manages, from the local DB.
class WatchMyTeams implements StreamUseCase<List<Team>, String> {
  const WatchMyTeams(this._repo);
  final TeamsRepository _repo;

  @override
  Stream<List<Team>> call(String userId) => _repo.watchMyTeams(userId);
}
