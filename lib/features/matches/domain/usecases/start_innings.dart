import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/match.dart';
import '../repositories/matches_repository.dart';

/// Opens an innings — sets the on-strike trio (striker / non-striker /
/// opening bowler) on the match row and (for innings 1) flips status →
/// live. Used at ball 1 of innings 1 (after Match Start hands off without
/// a bowler) and at the start of the chase.
class StartInnings implements UseCase<Unit, StartInningsParams> {
  const StartInnings(this._repo);
  final MatchesRepository _repo;

  @override
  Future<Either<Failure, Unit>> call(StartInningsParams p) {
    if (p.strikerId.isEmpty || p.nonStrikerId.isEmpty || p.bowlerId.isEmpty) {
      return Future.value(const Left(
        ValidationFailure(
          'Striker, non-striker, and bowler are all required',
        ),
      ));
    }
    if (p.strikerId == p.nonStrikerId) {
      return Future.value(const Left(
        ValidationFailure('Striker and non-striker must be different'),
      ));
    }
    return _repo.startInnings(
      matchId: p.matchId,
      inningsNumber: p.inningsNumber,
      strikerId: p.strikerId,
      nonStrikerId: p.nonStrikerId,
      bowlerId: p.bowlerId,
    );
  }
}

class StartInningsParams {
  const StartInningsParams({
    required this.matchId,
    required this.inningsNumber,
    required this.strikerId,
    required this.nonStrikerId,
    required this.bowlerId,
  });

  final MatchId matchId;
  final int inningsNumber;
  final String strikerId;
  final String nonStrikerId;
  final String bowlerId;
}
