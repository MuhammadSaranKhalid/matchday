import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/match_request.dart';
import '../repositories/match_pool_repository.dart';

/// Clean Architecture Use Case: Find a match challenge by 6-digit share code.
class FindMatchChallengeByCodeUseCase {
  const FindMatchChallengeByCodeUseCase(this._repository);

  final MatchPoolRepository _repository;

  Future<Either<Failure, MatchRequest?>> call(String code) {
    return _repository.findChallengeByCode(code);
  }
}
