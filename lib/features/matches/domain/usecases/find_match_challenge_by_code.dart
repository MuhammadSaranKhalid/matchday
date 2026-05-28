import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/match_request.dart';
import '../repositories/matches_repository.dart';

/// Resolve a 6-digit in-person share code to a match request. Returns null
/// when the code is unknown, expired, or invisible to the caller.
class FindMatchChallengeByCode implements UseCase<MatchRequest?, String> {
  const FindMatchChallengeByCode(this._repo);
  final MatchesRepository _repo;

  @override
  Future<Either<Failure, MatchRequest?>> call(String code) {
    final trimmed = code.trim();
    if (trimmed.length != 6 || int.tryParse(trimmed) == null) {
      return Future.value(const Left(
        ValidationFailure('Share code must be 6 digits'),
      ));
    }
    return _repo.findMatchChallengeByCode(trimmed);
  }
}
