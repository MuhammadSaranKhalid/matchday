import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../teams/domain/entities/team.dart';
import '../entities/match.dart';
import '../entities/match_pool_application.dart';
import '../entities/match_request.dart';

/// Clean Architecture domain contract for Match Pool & Broadcasting operations.
abstract class MatchPoolRepository {
  /// Fetch all active match challenge broadcasts created by other teams (the general open pool).
  Future<Either<Failure, List<MatchRequest>>> getOpenPoolChallenges();

  /// Fetch all active match challenge broadcasts created by user's teams.
  Future<Either<Failure, List<MatchRequest>>> getMyPoolBroadcasts({
    required Set<TeamId> myTeamIds,
  });

  /// Every open challenge hosted by [myTeamIds], whatever its status.
  ///
  /// [getMyPoolBroadcasts] narrows this to the live ones for the side-panel
  /// badge; the My-challenges screen needs the settled ones too so it can
  /// draw its "Past · closed" section.
  Future<Either<Failure, List<MatchRequest>>> getMyPoolChallenges({
    required Set<TeamId> myTeamIds,
  });

  /// Find a match challenge by 6-digit share code.
  Future<Either<Failure, MatchRequest?>> findChallengeByCode(String code);

  /// Submit an application for an open pool challenge request.
  Future<Either<Failure, String>> applyToMatchPool({
    required MatchRequestId requestId,
    required TeamId teamId,
    List<String> xi = const [],
    String? keeperId,
    String? message,
  });

  /// List all applications submitted for a match challenge.
  Future<Either<Failure, List<MatchPoolApplication>>> listPoolApplications(
    MatchRequestId requestId,
  );

  /// Host captain accepts an applicant to lock in the match fixture.
  Future<Either<Failure, MatchId>> acceptPoolApplication({
    required String applicationId,
    String? decisionNote,
  });

  /// Host captain rejects an applicant.
  Future<Either<Failure, Unit>> rejectPoolApplication({
    required String applicationId,
    String? reason,
  });

  /// Applicant withdraws their pending application.
  Future<Either<Failure, Unit>> withdrawPoolApplication({
    required String applicationId,
  });
}
