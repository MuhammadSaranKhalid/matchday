import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../teams/domain/entities/team.dart';
import '../entities/match_request.dart';
import '../repositories/match_pool_repository.dart';

/// Clean Architecture Use Case: Apply to an open match pool challenge.
class ApplyToMatchPoolUseCase {
  const ApplyToMatchPoolUseCase(this._repository);

  final MatchPoolRepository _repository;

  Future<Either<Failure, String>> call({
    required MatchRequestId requestId,
    required TeamId teamId,
    List<String> xi = const [],
    String? keeperId,
    String? message,
  }) {
    return _repository.applyToMatchPool(
      requestId: requestId,
      teamId: teamId,
      xi: xi,
      keeperId: keeperId,
      message: message,
    );
  }
}
