import '../../../../core/usecase/usecase.dart';
import '../entities/roster_member.dart';
import '../entities/team.dart';
import '../repositories/teams_repository.dart';

/// Streams a team's active roster (members joined with their display names).
class WatchRoster implements StreamUseCase<List<RosterMember>, TeamId> {
  const WatchRoster(this._repo);
  final TeamsRepository _repo;

  @override
  Stream<List<RosterMember>> call(TeamId teamId) => _repo.watchRoster(teamId);
}
