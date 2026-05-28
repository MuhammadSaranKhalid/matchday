import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/match.dart';
import '../repositories/matches_repository.dart';

class StartMatchNow implements UseCase<Unit, MatchId> {
  const StartMatchNow(this._repo);
  final MatchesRepository _repo;

  @override
  Future<Either<Failure, Unit>> call(MatchId id) => _repo.startMatchNow(id);
}
