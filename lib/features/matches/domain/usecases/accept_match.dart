import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/match.dart';
import '../repositories/matches_repository.dart';

/// Opponent accepts a pending match by locking team B's XI. Same XI rules as
/// the sender: exactly `playersPerTeam`, captain (and keeper, if set) in the XI.
class AcceptMatch implements UseCase<Match, AcceptMatchParams> {
  const AcceptMatch(this._repo);
  final MatchesRepository _repo;

  @override
  Future<Either<Failure, Match>> call(AcceptMatchParams p) async {
    if (p.squad.length != p.playersPerTeam) {
      return Left(ValidationFailure('Pick exactly ${p.playersPerTeam} players'));
    }
    if (!p.squad.contains(p.captain)) {
      return const Left(ValidationFailure('Captain must be in the XI'));
    }
    if (p.keeper != null && !p.squad.contains(p.keeper)) {
      return const Left(ValidationFailure('Keeper must be in the XI'));
    }
    return _repo.acceptMatch(
      id: p.id,
      squad: p.squad,
      captain: p.captain,
      keeper: p.keeper,
    );
  }
}

class AcceptMatchParams {
  const AcceptMatchParams({
    required this.id,
    required this.playersPerTeam,
    required this.squad,
    required this.captain,
    this.keeper,
  });

  final MatchId id;
  final int playersPerTeam;
  final List<String> squad;
  final String captain;
  final String? keeper;
}
