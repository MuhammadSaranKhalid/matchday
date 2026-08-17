import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../repositories/match_pool_repository.dart';

/// Clean Architecture Use Case: Reject a team's pool application.
class RejectPoolApplicationUseCase {
  const RejectPoolApplicationUseCase(this._repository);

  final MatchPoolRepository _repository;

  Future<Either<Failure, Unit>> call({
    required String applicationId,
    String? reason,
  }) {
    return _repository.rejectPoolApplication(
      applicationId: applicationId,
      reason: reason,
    );
  }
}
