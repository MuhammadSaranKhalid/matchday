import 'package:fpdart/fpdart.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/follow.dart';
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
}
