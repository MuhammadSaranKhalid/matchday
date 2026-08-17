import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../teams/domain/entities/team.dart';
import '../entities/match.dart';
import '../repositories/matches_repository.dart';

class RecordMatchTossUseCase {
  const RecordMatchTossUseCase(this._repository);

  final MatchesRepository _repository;

  Future<Either<Failure, Unit>> call({
    required MatchId id,
    required TeamId wonBy,
    required TossDecision decision,
    String? face,
  }) {
    return _repository.recordMatchToss(
      id: id,
      wonBy: wonBy,
      decision: decision,
      face: face,
    );
  }
}
