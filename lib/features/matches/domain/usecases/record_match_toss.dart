import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../teams/domain/entities/team.dart';
import '../entities/match.dart';
import '../repositories/matches_repository.dart';

class RecordMatchToss implements UseCase<Unit, RecordMatchTossParams> {
  const RecordMatchToss(this._repo);
  final MatchesRepository _repo;

  @override
  Future<Either<Failure, Unit>> call(RecordMatchTossParams p) =>
      _repo.recordMatchToss(
        id: p.matchId,
        wonBy: p.wonBy,
        decision: p.decision,
        face: p.face,
      );
}

class RecordMatchTossParams {
  const RecordMatchTossParams({
    required this.matchId,
    required this.wonBy,
    required this.decision,
    this.face,
  });

  final MatchId matchId;
  final TeamId wonBy;
  final TossDecision decision;
  final String? face;
}
