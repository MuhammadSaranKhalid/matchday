import 'package:fpdart/fpdart.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/post.dart';
import '../../domain/repositories/post_read_repository.dart';
import '../datasources/posts_remote_datasource.dart';

/// CQRS Read Repository Implementation.
/// Exclusively handles query projection queries (Home Feed, Profile Posts, Saved Posts, Post Detail).
class PostReadRepositoryImpl implements PostReadRepository {
  PostReadRepositoryImpl(this._remote);

  final PostsRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<Post>>> getHomeFeed({
    String mode = 'home',
    String filter = 'all',
    String? targetId,
    DateTime? cursorPublishedAt,
    String? cursorPostId,
    int limit = 20,
  }) async {
    try {
      final dtos = await _remote.getHomeFeed(
        mode: mode,
        filter: filter,
        targetId: targetId,
        cursorPublishedAt: cursorPublishedAt,
        cursorPostId: cursorPostId,
        limit: limit,
      );
      return Right(
        dtos.map((d) => d.toEntity(urlFactory: _remote.urlFactory)).toList(),
      );
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Post>>> getProfilePosts({
    required String publisherId,
    PostPublisherType publisherType = PostPublisherType.user,
    DateTime? cursorPublishedAt,
    String? cursorPostId,
    int limit = 20,
  }) async {
    try {
      final dtos = await _remote.getProfilePosts(
        publisherId: publisherId,
        publisherType: publisherType.name,
        cursorPublishedAt: cursorPublishedAt,
        cursorPostId: cursorPostId,
        limit: limit,
      );
      return Right(
        dtos.map((d) => d.toEntity(urlFactory: _remote.urlFactory)).toList(),
      );
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Post>>> getSavedPosts({
    DateTime? cursorSavedAt,
    String? cursorPostId,
    int limit = 20,
  }) async {
    try {
      final dtos = await _remote.getSavedPosts(
        cursorSavedAt: cursorSavedAt,
        cursorPostId: cursorPostId,
        limit: limit,
      );
      return Right(
        dtos.map((d) => d.toEntity(urlFactory: _remote.urlFactory)).toList(),
      );
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Post>> getPost(PostId id) async {
    try {
      final dto = await _remote.getPost(id.value);
      return Right(dto.toEntity(urlFactory: _remote.urlFactory));
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
