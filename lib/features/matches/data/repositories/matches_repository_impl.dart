import 'package:fpdart/fpdart.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../teams/domain/entities/team.dart';
import '../../domain/entities/innings.dart';
import '../../domain/entities/match.dart';
import '../../domain/repositories/matches_repository.dart';
import '../datasources/matches_remote_datasource.dart';

/// Online-only matches repository. The only place the remote data source's raw
/// exceptions become [Failure]s.
class MatchesRepositoryImpl implements MatchesRepository {
  MatchesRepositoryImpl(this._remote, {Uuid? uuid})
      : _uuid = uuid ?? const Uuid();

  final MatchesRemoteDataSource _remote;
  final Uuid _uuid;

  @override
  Future<Either<Failure, Match>> createMatchRequest({
    required TeamId teamAId,
    required TeamId teamBId,
    required MatchFormat format,
    required List<String> squad,
    required String captain,
    String? keeper,
    Venue? venue,
    DateTime? scheduledStartTime,
  }) async {
    try {
      final dto = await _remote.create({
        'match_id': _uuid.v4(),
        'match_type': 'friendly',
        'team_a_id': teamAId.value,
        'team_b_id': teamBId.value,
        'team_a_squad': squad,
        'team_a_captain': captain,
        if (keeper != null) 'team_a_keeper': keeper,
        'format': {
          'overs_per_innings': format.oversPerInnings,
          'players_per_team': format.playersPerTeam,
          'ball_type': format.ballType.wire,
          'max_overs_per_bowler': format.maxOversPerBowler,
        },
        if (venue != null)
          'venue': {
            'ground': venue.ground,
            if (venue.city != null) 'city': venue.city,
          },
        if (scheduledStartTime != null)
          'scheduled_start_time': scheduledStartTime.toIso8601String(),
        'scoring_mode': 'live_ball_by_ball',
        'status': 'pending',
      });
      return Right(dto.toEntity());
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Match?>> getMatch(MatchId id) async {
    try {
      final dto = await _remote.getById(id.value);
      return Right(dto?.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Match>>> listMyMatches() async {
    try {
      final dtos = await _remote.list();
      return Right(dtos.map((d) => d.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Match>> acceptMatch({
    required MatchId id,
    required List<String> squad,
    required String captain,
    String? keeper,
  }) =>
      _update(id, {
        'team_b_squad': squad,
        'team_b_captain': captain,
        if (keeper != null) 'team_b_keeper': keeper,
        'status': 'accepted',
      });

  @override
  Future<Either<Failure, Match>> declineMatch({
    required MatchId id,
    String? reason,
  }) =>
      _update(id, {
        'status': 'declined',
        if (reason != null) 'decline_reason': {'reason': reason},
      });

  @override
  Future<Either<Failure, Innings>> startMatch({
    required MatchId id,
    required TeamId tossWonBy,
    required TossDecision tossDecision,
    required TeamId battingTeamId,
    required TeamId bowlingTeamId,
    required String strikerId,
    required String nonStrikerId,
    required String bowlerId,
  }) async {
    try {
      // 1) Create innings 1 (client-generated id).
      final inningsDto = await _remote.createInnings({
        'innings_id': _uuid.v4(),
        'match_id': id.value,
        'innings_number': 1,
        'batting_team_id': battingTeamId.value,
        'bowling_team_id': bowlingTeamId.value,
        'status': 'in_progress',
        'current_striker_id': strikerId,
        'current_non_striker_id': nonStrikerId,
        'current_bowler_id': bowlerId,
      });
      // 2) Flip the match to live (toss recorded).
      await _remote.update(id.value, {
        'toss_won_by': tossWonBy.value,
        'toss_decision': tossDecision.wire,
        'status': 'live',
        'current_innings': 1,
        'actual_start_time': DateTime.now().toIso8601String(),
      });
      return Right(inningsDto.toEntity());
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  Future<Either<Failure, Match>> _update(
    MatchId id,
    Map<String, dynamic> changes,
  ) async {
    try {
      final dto = await _remote.update(id.value, changes);
      return Right(dto.toEntity());
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
