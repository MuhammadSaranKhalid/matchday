import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/match.dart';
import '../entities/match_innings_state.dart';
import '../repositories/matches_repository.dart';

class GetMatchInningsStateUseCase {
  const GetMatchInningsStateUseCase(this._repository);

  final MatchesRepository _repository;

  Future<Either<Failure, MatchInningsState?>> call({
    required MatchId matchId,
    required int inningsNumber,
  }) {
    return _repository.getMatchInningsState(
      matchId: matchId,
      inningsNumber: inningsNumber,
    );
  }
}
