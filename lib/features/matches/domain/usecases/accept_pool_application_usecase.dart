import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/match.dart';
import '../repositories/match_pool_repository.dart';

/// Clean Architecture Use Case: Accept a team's pool application.
class AcceptPoolApplicationUseCase {
  const AcceptPoolApplicationUseCase(this._repository);

  final MatchPoolRepository _repository;

  Future<Either<Failure, MatchId>> call({
    required String applicationId,
    String? decisionNote,
  }) {
    return _repository.acceptPoolApplication(
      applicationId: applicationId,
      decisionNote: decisionNote,
    );
  }
}
