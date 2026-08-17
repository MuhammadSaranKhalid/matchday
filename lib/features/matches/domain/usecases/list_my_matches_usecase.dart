import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/match.dart';
import '../repositories/matches_repository.dart';

class ListMyMatchesUseCase {
  const ListMyMatchesUseCase(this._repository);

  final MatchesRepository _repository;

  Future<Either<Failure, List<Match>>> call() {
    return _repository.listMyMatches();
  }
}
