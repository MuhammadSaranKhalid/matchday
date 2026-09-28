import 'package:fpdart/fpdart.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../auth/domain/entities/user.dart';
import '../../domain/entities/follow.dart';
import '../../domain/entities/follow_counts.dart';
import '../../domain/entities/follow_direction.dart';
import '../../domain/entities/follow_list_entry.dart';
import '../../domain/repositories/follows_repository.dart';
import '../datasources/follows_remote_datasource.dart';

/// Online-only follows repository.
///
/// This is the ONLY place raw exceptions from [FollowsRemoteDataSource] are
/// translated to [Failure] subtypes per CLAUDE.md Rule 2 and §6.1.
///
/// Exception-to-Failure mapping order:
///   [UnauthorizedException] → [AuthFailure]
///   [ServerException]       → [ServerFailure]
///   catch-all               → [UnknownFailure]
class FollowsRepositoryImpl implements FollowsRepository {
  FollowsRepositoryImpl(this._remote);
  final FollowsRemoteDataSource _remote;

  @override
  Future<Either<Failure, Follow>> follow(FollowTarget target) async {
    try {
      final dto = await _remote.follow(target);
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
  Future<Either<Failure, Unit>> unfollow(FollowTarget target) async {
    try {
      await _remote.unfollow(target);
      return const Right(unit);
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> areNotificationsEnabled(
    FollowTarget target,
  ) async {
    try {
      return Right(await _remote.areNotificationsEnabled(target));
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> setNotificationsEnabled(
    FollowTarget target, {
    required bool enabled,
  }) async {
    try {
      await _remote.setNotificationsEnabled(target, enabled: enabled);
      return const Right(unit);
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

  @override
  Future<Either<Failure, List<String>>> listFollowedTeamIds() async {
    try {
      return Right(await _remote.listFollowedTeamIds());
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> isFollowing(FollowTarget target) async {
    try {
      final result = await _remote.isFollowing(target);
      return Right(result);
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<FollowListEntry>>> getFollowList(
    UserId userId,
    FollowDirection direction, {
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final dtos = await _remote.listFollowList(
        userId.value,
        direction.wire,
        limit: limit,
        offset: offset,
      );
      return Right(dtos.map((d) => d.toEntity()).toList());
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, FollowCounts>> getFollowCounts(UserId userId) async {
    try {
      final counts = await _remote.countFollows(userId.value);
      return Right(counts);
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
