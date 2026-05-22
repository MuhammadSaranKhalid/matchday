import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../teams/domain/entities/team.dart';
import '../entities/innings.dart';
import '../entities/match.dart';
import '../repositories/matches_repository.dart';

/// Start a match: derive the batting/bowling sides from the toss, validate the
/// openers against each side's XI, then persist (creates innings 1, match → live).
class StartMatch implements UseCase<Innings, StartMatchParams> {
  const StartMatch(this._repo);
  final MatchesRepository _repo;

  @override
  Future<Either<Failure, Innings>> call(StartMatchParams p) async {
    final m = p.match;
    if (m.status != MatchStatus.accepted) {
      return const Left(ValidationFailure('Match is not ready to start'));
    }
    if (p.tossWonBy != m.teamAId && p.tossWonBy != m.teamBId) {
      return const Left(ValidationFailure('Toss winner must be one of the teams'));
    }

    // bat → toss winner bats; bowl → toss winner fields.
    final winnerBats = p.tossDecision == TossDecision.bat;
    final battingTeamId = winnerBats
        ? p.tossWonBy
        : (p.tossWonBy == m.teamAId ? m.teamBId : m.teamAId);
    final bowlingTeamId =
        battingTeamId == m.teamAId ? m.teamBId : m.teamAId;

    final battingSquad =
        battingTeamId == m.teamAId ? m.teamASquad : m.teamBSquad;
    final bowlingSquad =
        bowlingTeamId == m.teamAId ? m.teamASquad : m.teamBSquad;

    if (p.strikerId == p.nonStrikerId) {
      return const Left(
          ValidationFailure('Striker and non-striker must be different'));
    }
    if (!battingSquad.contains(p.strikerId) ||
        !battingSquad.contains(p.nonStrikerId)) {
      return const Left(
          ValidationFailure('Openers must be in the batting XI'));
    }
    if (!bowlingSquad.contains(p.bowlerId)) {
      return const Left(
          ValidationFailure('Bowler must be in the bowling XI'));
    }

    return _repo.startMatch(
      id: m.id,
      tossWonBy: p.tossWonBy,
      tossDecision: p.tossDecision,
      battingTeamId: battingTeamId,
      bowlingTeamId: bowlingTeamId,
      strikerId: p.strikerId,
      nonStrikerId: p.nonStrikerId,
      bowlerId: p.bowlerId,
    );
  }
}

class StartMatchParams {
  const StartMatchParams({
    required this.match,
    required this.tossWonBy,
    required this.tossDecision,
    required this.strikerId,
    required this.nonStrikerId,
    required this.bowlerId,
  });

  final Match match;
  final TeamId tossWonBy;
  final TossDecision tossDecision;
  final String strikerId;
  final String nonStrikerId;
  final String bowlerId;
}
