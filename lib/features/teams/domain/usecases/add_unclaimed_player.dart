import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/team.dart';
import '../repositories/teams_repository.dart';
import '../value_objects/player_display_name.dart';

/// Add a player to a team's roster by name (unclaimed). Validates the name via
/// [PlayerDisplayName] before reaching the repository.
class AddUnclaimedPlayer implements UseCase<Unit, AddUnclaimedPlayerParams> {
  const AddUnclaimedPlayer(this._repo);
  final TeamsRepository _repo;

  @override
  Future<Either<Failure, Unit>> call(AddUnclaimedPlayerParams p) {
    return PlayerDisplayName.create(p.displayName).fold(
      (f) async => Left(f),
      (name) => _repo.addUnclaimedPlayer(teamId: p.teamId, displayName: name),
    );
  }
}

class AddUnclaimedPlayerParams {
  const AddUnclaimedPlayerParams({
    required this.teamId,
    required this.displayName,
  });

  final TeamId teamId;
  final String displayName;
}
