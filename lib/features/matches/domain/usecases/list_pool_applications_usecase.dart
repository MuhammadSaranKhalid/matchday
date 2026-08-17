import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/match_pool_application.dart';
import '../entities/match_request.dart';
import '../repositories/match_pool_repository.dart';

/// Clean Architecture Use Case: List applications for a match pool challenge.
class ListPoolApplicationsUseCase {
  const ListPoolApplicationsUseCase(this._repository);

  final MatchPoolRepository _repository;

  Future<Either<Failure, List<MatchPoolApplication>>> call(
    MatchRequestId requestId,
  ) {
    return _repository.listPoolApplications(requestId);
  }
}
