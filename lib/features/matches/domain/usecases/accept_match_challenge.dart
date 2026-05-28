import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../teams/domain/entities/team.dart';
import '../entities/match.dart';
import '../entities/match_request.dart';
import '../repositories/matches_repository.dart';

class AcceptMatchChallenge
    implements UseCase<MatchId, AcceptMatchChallengeParams> {
  const AcceptMatchChallenge(this._repo);
  final MatchesRepository _repo;

  @override
  Future<Either<Failure, MatchId>> call(AcceptMatchChallengeParams p) =>
      _repo.acceptMatchChallenge(
        requestId: p.requestId,
        scheduledStartTime: p.scheduledStartTime,
        venue: p.venue,
        format: p.format,
        decisionNote: p.decisionNote,
        toTeamId: p.toTeamId,
        toTeamXi: p.toTeamXi,
        toTeamKeeperId: p.toTeamKeeperId,
      );
}

class AcceptMatchChallengeParams {
  const AcceptMatchChallengeParams({
    required this.requestId,
    this.scheduledStartTime,
    this.venue,
    this.format,
    this.decisionNote,
    this.toTeamId,
    this.toTeamXi = const [],
    this.toTeamKeeperId,
  });

  final MatchRequestId requestId;
  final DateTime? scheduledStartTime;
  final String? venue;
  final MatchFormat? format;
  final String? decisionNote;
  final TeamId? toTeamId;
  final List<String> toTeamXi;
  final String? toTeamKeeperId;
}
