import '../../../../core/usecase/usecase.dart';
import '../entities/team.dart';
import '../repositories/teams_repository.dart';

/// Streams all cached teams (for the match-setup opponent picker).
class WatchAllTeams implements StreamUseCase<List<Team>, NoParams> {
  const WatchAllTeams(this._repo);
  final TeamsRepository _repo;

  @override
  Stream<List<Team>> call(NoParams params) => _repo.watchAllTeams();
}
