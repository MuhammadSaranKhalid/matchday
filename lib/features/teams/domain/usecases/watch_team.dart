import '../../../../core/usecase/usecase.dart';
import '../entities/team.dart';
import '../repositories/teams_repository.dart';

/// Streams a single team (the hub view). Emits null if the team can't be
/// found (deleted or not accessible to the signed-in user).
class WatchTeam implements StreamUseCase<Team?, TeamId> {
  const WatchTeam(this._repo);
  final TeamsRepository _repo;

  @override
  Stream<Team?> call(TeamId id) => _repo.watchTeam(id);
}
