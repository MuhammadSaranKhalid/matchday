import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/match_request.dart';
import '../repositories/match_pool_repository.dart';

/// Clean Architecture Use Case: Get open match pool challenges.
class GetOpenMatchPoolUseCase {
  const GetOpenMatchPoolUseCase(this._repository);

  final MatchPoolRepository _repository;

  Future<Either<Failure, List<MatchRequest>>> call() {
    return _repository.getOpenPoolChallenges();
  }
}
