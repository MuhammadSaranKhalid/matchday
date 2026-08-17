import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../teams/domain/entities/team.dart';
import '../entities/match.dart';
import '../entities/match_request.dart';
import '../repositories/matches_repository.dart';

class SendMatchChallengeUseCase {
  const SendMatchChallengeUseCase(this._repository);

  final MatchesRepository _repository;

  Future<Either<Failure, MatchRequestId>> call({
    required TeamId fromTeamId,
    TeamId? toTeamId,
    DateTime? proposedStartTime,
    String? proposedVenue,
    MatchFormat? proposedFormat,
    String? message,
    int playersPerSide = 11,
    List<String> fromTeamXi = const [],
    String? fromTeamKeeperId,
  }) {
    return _repository.sendMatchChallenge(
      fromTeamId: fromTeamId,
      toTeamId: toTeamId,
      proposedStartTime: proposedStartTime,
      proposedVenue: proposedVenue,
      proposedFormat: proposedFormat,
      message: message,
      playersPerSide: playersPerSide,
      fromTeamXi: fromTeamXi,
      fromTeamKeeperId: fromTeamKeeperId,
    );
  }
}
