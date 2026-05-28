import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../teams/domain/entities/team.dart';
import '../entities/match.dart';
import '../entities/match_request.dart';
import '../repositories/matches_repository.dart';

class SendMatchChallenge
    implements UseCase<MatchRequestId, SendMatchChallengeParams> {
  const SendMatchChallenge(this._repo);
  final MatchesRepository _repo;

  @override
  Future<Either<Failure, MatchRequestId>> call(
      SendMatchChallengeParams p) async {
    if (p.message != null && p.message!.length > 500) {
      return const Left(ValidationFailure('Message too long (max 500 chars)'));
    }
    if (p.playersPerSide < 5 || p.playersPerSide > 15) {
      return const Left(
        ValidationFailure('Players per side must be between 5 and 15'),
      );
    }
    if (p.fromTeamXi.length > p.playersPerSide) {
      return const Left(
        ValidationFailure('XI has more players than players_per_side'),
      );
    }
    return _repo.sendMatchChallenge(
      fromTeamId: p.fromTeamId,
      toTeamId: p.toTeamId,
      proposedStartTime: p.proposedStartTime,
      proposedVenue: p.proposedVenue,
      proposedFormat: p.proposedFormat,
      message: p.message?.trim(),
      playersPerSide: p.playersPerSide,
      fromTeamXi: p.fromTeamXi,
      fromTeamKeeperId: p.fromTeamKeeperId,
    );
  }
}

class SendMatchChallengeParams {
  const SendMatchChallengeParams({
    required this.fromTeamId,
    this.toTeamId,
    this.proposedStartTime,
    this.proposedVenue,
    this.proposedFormat,
    this.message,
    this.playersPerSide = 11,
    this.fromTeamXi = const [],
    this.fromTeamKeeperId,
  });

  final TeamId fromTeamId;
  final TeamId? toTeamId;
  final DateTime? proposedStartTime;
  final String? proposedVenue;
  final MatchFormat? proposedFormat;
  final String? message;
  final int playersPerSide;
  final List<String> fromTeamXi;
  final String? fromTeamKeeperId;
}
