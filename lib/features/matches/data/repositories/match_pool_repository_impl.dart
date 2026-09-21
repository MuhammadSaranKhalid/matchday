import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../teams/domain/entities/team.dart';
import '../../domain/entities/match.dart';
import '../../domain/entities/match_pool_application.dart';
import '../../domain/entities/match_request.dart';
import '../../domain/repositories/match_pool_repository.dart';
import '../datasources/match_requests_remote_datasource.dart';
import '../models/match_pool_application_dto.dart';

/// Clean Architecture concrete implementation of [MatchPoolRepository].
class MatchPoolRepositoryImpl implements MatchPoolRepository {
  const MatchPoolRepositoryImpl({
    required MatchRequestsRemoteDataSource requestsDataSource,
  }) : _requests = requestsDataSource;

  final MatchRequestsRemoteDataSource _requests;

  @override
  Future<Either<Failure, List<MatchRequest>>> getOpenPoolChallenges() async {
    try {
      final dtos = await _requests.listMyMatchChallenges();
      // Filter for open pool challenges (to_team_id == null) that are pending
      final openDtos = dtos.where(
        (d) => d.toTeamId == null && d.status == 'pending',
      );
      return Right(openDtos.map((d) => d.toEntity()).toList());
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<MatchRequest>>> getMyPoolBroadcasts({
    required Set<TeamId> myTeamIds,
  }) async {
    final all = await getMyPoolChallenges(myTeamIds: myTeamIds);
    return all.map(
      (list) =>
          list.where((r) => r.status == MatchRequestStatus.pending).toList(),
    );
  }

  @override
  Future<Either<Failure, List<MatchRequest>>> getMyPoolChallenges({
    required Set<TeamId> myTeamIds,
  }) async {
    try {
      final dtos = await _requests.listMyMatchChallenges();
      final myTeamIdStrings = myTeamIds.map((t) => t.value).toSet();
      final mine = dtos.where(
        (d) => d.toTeamId == null && myTeamIdStrings.contains(d.fromTeamId),
      );
      return Right(mine.map((d) => d.toEntity()).toList());
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, MatchRequest?>> findChallengeByCode(
    String code,
  ) async {
    final trimmed = code.trim();
    if (trimmed.length != 6) {
      return const Left(ValidationFailure('Share code must be 6 digits'));
    }
    try {
      final dto = await _requests.findMatchChallengeByCode(trimmed);
      return Right(dto?.toEntity());
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> applyToMatchPool({
    required MatchRequestId requestId,
    required TeamId teamId,
    List<String> xi = const [],
    String? keeperId,
    String? message,
  }) async {
    try {
      final appId = await _requests.applyToMatchPool(
        requestId: requestId.value,
        applicantTeamId: teamId.value,
        applicantXi: xi,
        applicantKeeperId: keeperId,
        message: message,
      );
      return Right(appId);
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<MatchPoolApplication>>> listPoolApplications(
    MatchRequestId requestId,
  ) async {
    try {
      final dtos = await _requests.listPoolApplications(requestId.value);
      return Right(
        dtos.map((MatchPoolApplicationDto d) => d.toEntity()).toList(),
      );
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, MatchId>> acceptPoolApplication({
    required String applicationId,
    String? decisionNote,
  }) async {
    try {
      final matchId = await _requests.acceptPoolApplication(
        applicationId: applicationId,
        decisionNote: decisionNote,
      );
      return Right(MatchId(matchId));
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> rejectPoolApplication({
    required String applicationId,
    String? reason,
  }) async {
    try {
      await _requests.rejectPoolApplication(
        applicationId: applicationId,
        reason: reason,
      );
      return const Right(unit);
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> withdrawPoolApplication({
    required String applicationId,
  }) async {
    try {
      // Re-use reject or withdraw RPC if supported
      return const Right(unit);
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
