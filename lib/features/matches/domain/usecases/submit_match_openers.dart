import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/match.dart';
import '../repositories/matches_repository.dart';

class SubmitMatchOpeners implements UseCase<Unit, SubmitMatchOpenersParams> {
  const SubmitMatchOpeners(this._repo);
  final MatchesRepository _repo;

  @override
  Future<Either<Failure, Unit>> call(SubmitMatchOpenersParams p) {
    if (p.strikerId == p.nonStrikerId) {
      return Future.value(const Left(
        ValidationFailure('Striker and non-striker must be different players'),
      ));
    }
    if (p.strikerId.isEmpty || p.nonStrikerId.isEmpty) {
      return Future.value(const Left(
        ValidationFailure('Both openers are required'),
      ));
    }
    return _repo.submitMatchOpeners(
      id: p.matchId,
      strikerId: p.strikerId,
      nonStrikerId: p.nonStrikerId,
    );
  }
}

class SubmitMatchOpenersParams {
  const SubmitMatchOpenersParams({
    required this.matchId,
    required this.strikerId,
    required this.nonStrikerId,
  });

  final MatchId matchId;
  final String strikerId;
  final String nonStrikerId;
}
