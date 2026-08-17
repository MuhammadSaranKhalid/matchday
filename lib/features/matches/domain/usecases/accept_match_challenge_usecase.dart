import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../teams/domain/entities/team.dart';
import '../entities/match.dart';
import '../entities/match_request.dart';
import '../repositories/matches_repository.dart';

class AcceptMatchChallengeUseCase {
  const AcceptMatchChallengeUseCase(this._repository);

  final MatchesRepository _repository;

  Future<Either<Failure, MatchId>> call({
    required MatchRequestId requestId,
    DateTime? scheduledStartTime,
    String? venue,
    MatchFormat? format,
    String? decisionNote,
    TeamId? toTeamId,
    List<String> toTeamXi = const [],
    String? toTeamKeeperId,
  }) {
    return _repository.acceptMatchChallenge(
      requestId: requestId,
      scheduledStartTime: scheduledStartTime,
      venue: venue,
      format: format,
      decisionNote: decisionNote,
      toTeamId: toTeamId,
      toTeamXi: toTeamXi,
      toTeamKeeperId: toTeamKeeperId,
    );
  }
}
