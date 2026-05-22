import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/match.dart';
import '../repositories/matches_repository.dart';

/// Matches involving any team the signed-in user owns or manages.
class ListMyMatches implements UseCase<List<Match>, NoParams> {
  const ListMyMatches(this._repo);
  final MatchesRepository _repo;

  @override
  Future<Either<Failure, List<Match>>> call(NoParams params) =>
      _repo.listMyMatches();
}
