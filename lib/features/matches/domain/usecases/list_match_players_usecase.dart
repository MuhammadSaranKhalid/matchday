import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/match.dart';
import '../entities/match_player.dart';
import '../repositories/matches_repository.dart';

class ListMatchPlayersUseCase {
  const ListMatchPlayersUseCase(this._repository);

  final MatchesRepository _repository;

  Future<Either<Failure, List<MatchPlayer>>> call(MatchId matchId) {
    return _repository.listMatchPlayers(matchId);
  }
}
