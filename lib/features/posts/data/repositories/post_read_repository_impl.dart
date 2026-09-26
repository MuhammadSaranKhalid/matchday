import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/post.dart';
import '../../domain/entities/post_page.dart';
import '../../domain/repositories/post_read_repository.dart';
import '../datasources/posts_remote_datasource.dart';

/// CQRS Read Repository Implementation.
/// Exclusively handles query projection queries (Home Feed, Profile Posts, Saved Posts, Post Detail).
class PostReadRepositoryImpl implements PostReadRepository {
  PostReadRepositoryImpl(this._remote);

  final PostsRemoteDataSource _remote;

  @override
  Future<Either<Failure, PostPage>> getHomeFeed({
    HomeFeedMode mode = HomeFeedMode.discover,
    String filter = 'all',
    DateTime? cursorPublishedAt,
    String? cursorPostId,
    int limit = 20,
  }) async {
    try {
      final modeStr = switch (mode) {
        HomeFeedMode.following => 'following',
        HomeFeedMode.discover => 'home',
      };

      final dtos = await _remote.getHomeFeed(
        mode: modeStr,
        filter: filter,
        cursorPublishedAt: cursorPublishedAt,
        cursorPostId: cursorPostId,
        limit: limit,
      );
      final posts = dtos
          .map((d) => d.toEntity(urlFactory: _remote.urlFactory))
          .toList();
      final hasMore = posts.length == limit;
      final last = posts.isNotEmpty ? posts.last : null;

      return Right(
        PostPage(
          posts: posts,
          nextCursorPublishedAt: last?.publishedAt ?? last?.createdAt,
          nextCursorPostId: last?.id.value,
          hasMore: hasMore,
        ),
      );
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on PostgrestException catch (e) {
      return Left(ServerFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on SocketException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PostPage>> getProfilePosts({
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
      final posts = dtos
          .map((d) => d.toEntity(urlFactory: _remote.urlFactory))
          .toList();
      final hasMore = posts.length == limit;
      final last = posts.isNotEmpty ? posts.last : null;

      return Right(
        PostPage(
          posts: posts,
          nextCursorPublishedAt: last?.publishedAt ?? last?.createdAt,
          nextCursorPostId: last?.id.value,
          hasMore: hasMore,
        ),
      );
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on PostgrestException catch (e) {
      return Left(ServerFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on SocketException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, SavedPostsPage>> getSavedPosts({
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
      final posts = dtos
          .map((d) => d.toEntity(urlFactory: _remote.urlFactory))
          .toList();
      final hasMore = posts.length == limit;
      final last = posts.isNotEmpty ? posts.last : null;

      return Right(
        SavedPostsPage(
          posts: posts,
          nextCursorSavedAt: last?.viewer.bookmarkedAt,
          nextCursorPostId: last?.id.value,
          hasMore: hasMore,
        ),
      );
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on PostgrestException catch (e) {
      return Left(ServerFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on SocketException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Post>> getPost(PostId id) async {
    try {
      final dto = await _remote.getPost(id.value);
      return Right(dto.toEntity(urlFactory: _remote.urlFactory));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on PostgrestException catch (e) {
      return Left(ServerFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on SocketException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
