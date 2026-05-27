import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/player_skills.dart';
import '../entities/team.dart';
import '../repositories/teams_repository.dart';
import '../value_objects/jersey_number.dart';
import '../value_objects/player_display_name.dart';

/// Add a player to a team's roster by name (unclaimed). Validates the name via
/// [PlayerDisplayName] and the jersey number via [JerseyNumber] before
/// reaching the repository. Playing-skill enums are passed through unvalidated
/// — they are presentational metadata only.
class AddUnclaimedPlayer implements UseCase<Unit, AddUnclaimedPlayerParams> {
  const AddUnclaimedPlayer(this._repo);
  final TeamsRepository _repo;

  @override
  Future<Either<Failure, Unit>> call(AddUnclaimedPlayerParams p) async {
    final nameResult = PlayerDisplayName.create(p.displayName);
    if (nameResult.isLeft()) {
      return Left(nameResult.getLeft().toNullable()!);
    }
    final name = nameResult.getRight().toNullable()!;

    JerseyNumber? jersey;
    if (p.jerseyNumber != null) {
      final jerseyResult = JerseyNumber.create(p.jerseyNumber!);
      if (jerseyResult.isLeft()) {
        return Left(jerseyResult.getLeft().toNullable()!);
      }
      jersey = jerseyResult.getRight().toNullable();
    }

    return _repo.addUnclaimedPlayer(
      teamId: p.teamId,
      displayName: name,
      jerseyNumber: jersey,
      playingRole: p.playingRole,
      battingStyle: p.battingStyle,
      bowlingStyle: p.bowlingStyle,
    );
  }
}

class AddUnclaimedPlayerParams {
  const AddUnclaimedPlayerParams({
    required this.teamId,
    required this.displayName,
    this.jerseyNumber,
    this.playingRole,
    this.battingStyle,
    this.bowlingStyle,
  });

  final TeamId teamId;
  final String displayName;
  final int? jerseyNumber;
  final PlayingRole? playingRole;
  final BattingStyle? battingStyle;
  final BowlingStyle? bowlingStyle;
}
