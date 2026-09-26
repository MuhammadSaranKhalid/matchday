import 'dart:async';
import 'dart:io';

import 'package:fpdart/fpdart.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/pending_post.dart';
import '../../domain/entities/post.dart';
import '../../domain/entities/post_draft.dart';
import '../../domain/repositories/posts_repository.dart';
import '../../domain/value_objects/post_text.dart';
import '../datasources/posts_local_datasource.dart';
import '../datasources/posts_remote_datasource.dart';

/// Concrete PostsRepository implementation.
/// The only boundary where raw SDK exceptions are caught and transformed into typed Failures.
class PostsRepositoryImpl implements PostsRepository {
  PostsRepositoryImpl(
    this._remote, {
    PostsLocalDataSource? local,
  }) : _local = local ?? PostsLocalDataSourceImpl();

  final PostsRemoteDataSource _remote;
  final PostsLocalDataSource _local;

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
  Future<Either<Failure, Post>> getPost(PostId id) async {
    try {
      final dto = await _remote.getPost(id.value);
      return Right(dto.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> beginPublishPost({
    required PostPublisherType publisherType,
    required String publisherId,
    required PostKind postKind,
    required PostText text,
    required List<String> localPhotoPaths,
    String? linkedMatchId,
    String? linkedTournamentId,
    String? linkedTeamId,
  }) async {
    if (localPhotoPaths.length > 4) {
      return const Left(ValidationFailure('A post can have at most 4 photos.'));
    }

    try {
      final mediaItems = <Map<String, dynamic>>[];
      for (var i = 0; i < localPhotoPaths.length; i++) {
        mediaItems.add({
          'position': i,
          'source_width': 1080,
          'source_height': 1080,
        });
      }

      // 1. Reserve publishing session on Supabase
      final response = await _remote.beginPostPublish(
        publisherType: publisherType.name,
        publisherId: publisherId,
        postKind: switch (postKind) {
          PostKind.recruitment => 'recruitment',
          PostKind.matchAnnouncement => 'match_announcement',
          PostKind.matchResult => 'match_result',
          PostKind.tournamentUpdate => 'tournament_update',
          PostKind.rosterUpdate => 'roster_update',
          PostKind.milestone => 'milestone',
          _ => 'standard',
        },
        text: text.value,
        expectedMediaCount: localPhotoPaths.length,
        mediaItems: mediaItems,
        linkedMatchId: linkedMatchId,
        linkedTournamentId: linkedTournamentId,
        linkedTeamId: linkedTeamId,
      );

      final postId = response['post_id'] as String;
      final serverMedia = (response['media'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .toList() ??
          const [];

      // 2. Emit durable local pending post projection
      final pendingPost = PendingPost(
        postId: postId,
        text: text.value,
        localMediaPaths: localPhotoPaths,
        createdAt: DateTime.now(),
        status: localPhotoPaths.isEmpty
            ? PendingPostStatus.publishing
            : PendingPostStatus.uploading,
        progress: 0.0,
      );
      await _local.savePendingPost(pendingPost);

      // 3. Launch background staging uploads (async / decoupled)
      if (localPhotoPaths.isNotEmpty) {
        unawaited(_drainStagingUploads(postId, serverMedia, localPhotoPaths));
      }

      return Right(postId);
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  Future<void> _drainStagingUploads(
    String postId,
    List<Map<String, dynamic>> serverMedia,
    List<String> localPhotoPaths,
  ) async {
    try {
      final total = localPhotoPaths.length;
      var uploaded = 0;

      for (final mediaMeta in serverMedia) {
        final position = (mediaMeta['position'] as num?)?.toInt() ?? 0;
        final stagingPath = mediaMeta['staging_path'] as String?;

        if (position < localPhotoPaths.length && stagingPath != null) {
          final file = File(localPhotoPaths[position]);
          if (await file.exists()) {
            await _remote.uploadStagingMedia(
              stagingPath: stagingPath,
              file: file,
            );
          }
          uploaded++;
          final current = await _local.getPendingPosts();
          final existing = current.where((p) => p.postId == postId).firstOrNull;
          if (existing != null) {
            await _local.savePendingPost(
              existing.copyWith(
                progress: uploaded / total,
                status: uploaded == total
                    ? PendingPostStatus.publishing
                    : PendingPostStatus.uploading,
              ),
            );
          }
        }
      }
    } catch (e) {
      final current = await _local.getPendingPosts();
      final existing = current.where((p) => p.postId == postId).firstOrNull;
      if (existing != null) {
        await _local.savePendingPost(
          existing.copyWith(
            status: PendingPostStatus.failed,
            errorMessage: 'Upload failed: $e',
          ),
        );
      }
    }
  }

  @override
  Future<Either<Failure, Unit>> deletePost(PostId id) async {
    try {
      await _remote.deletePost(id.value);
      await _local.removePendingPost(id.value);
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> setPostLike(PostId id, {required bool liked}) async {
    try {
      final result = await _remote.setPostLike(id.value, liked: liked);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> setPostBookmark(PostId id, {required bool bookmarked}) async {
    try {
      final result = await _remote.setPostBookmark(id.value, bookmarked: bookmarked);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Stream<List<PendingPost>> watchPendingPosts() => _local.watchPendingPosts();

  @override
  Future<void> retryPendingPost(String postId) async {
    final list = await _local.getPendingPosts();
    final post = list.where((p) => p.postId == postId).firstOrNull;
    if (post == null) return;

    await _local.savePendingPost(
      post.copyWith(status: PendingPostStatus.uploading, errorMessage: null),
    );

    // Re-attempt upload flow
    if (post.localMediaPaths.isNotEmpty) {
      final dummyServerMedia = [
        for (var i = 0; i < post.localMediaPaths.length; i++)
          {
            'position': i,
            'staging_path': '${post.postId}/$i/source.jpg',
          }
      ];
      unawaited(_drainStagingUploads(postId, dummyServerMedia, post.localMediaPaths));
    }
  }

  @override
  Future<void> discardPendingPost(String postId) async {
    await _local.removePendingPost(postId);
  }

  @override
  Future<Either<Failure, Post>> createPost(PostDraft draft) async {
    final textResult = PostText.create(
      draft.text ?? '',
      hasPhotos: draft.photos.isNotEmpty,
    );

    return textResult.fold(
      (failure) => Left(failure),
      (postText) async {
        final publisherType = draft.authorContext == PostAuthorContext.teamManager
            ? PostPublisherType.team
            : PostPublisherType.user;

        final currentUid = _remote.currentUserId;
        if (currentUid == null) {
          return const Left(AuthFailure('You must be signed in to post.'));
        }

        final publisherId = draft.authorContext == PostAuthorContext.teamManager &&
                draft.contextEntityId != null
            ? draft.contextEntityId!
            : currentUid;

        final localPaths =
            draft.photos.map((ProcessedPhoto p) => p.file.path).toList();

        final publishResult = await beginPublishPost(
          publisherType: publisherType,
          publisherId: publisherId,
          postKind: PostKind.standard,
          text: postText,
          localPhotoPaths: localPaths,
          linkedTeamId: draft.authorContext == PostAuthorContext.teamManager
              ? draft.contextEntityId
              : null,
        );

        return publishResult.map(
          (postId) => Post(
            id: PostId(postId),
            createdByUserId: currentUid,
            publisher: PostPublisher(
              id: publisherId,
              type: publisherType,
              displayName: publisherType == PostPublisherType.team ? 'Team' : 'User',
            ),
            kind: PostKind.standard,
            text: postText.value,
            status: localPaths.isEmpty ? PostStatus.active : PostStatus.publishing,
            expectedMediaCount: localPaths.length,
            createdAt: DateTime.now(),
            publishedAt: localPaths.isEmpty ? DateTime.now() : null,
            linkedTeamId: draft.authorContext == PostAuthorContext.teamManager
                ? draft.contextEntityId
                : null,
          ),
        );
      },
    );
  }

  // ─── Legacy Fallback Implementations ────────────────────────────────────────

  @override
  Future<Either<Failure, List<Post>>> getFeed({
    int limit = 20,
    String filter = 'all',
    DateTime? before,
  }) =>
      getHomeFeed(
        mode: 'home',
        filter: filter,
        cursorPublishedAt: before,
        limit: limit,
      );

  @override
  Future<Either<Failure, List<Post>>> getAuthorPosts(
    String authorId, {
    int limit = 20,
    DateTime? before,
  }) =>
      getHomeFeed(
        mode: 'user',
        targetId: authorId,
        cursorPublishedAt: before,
        limit: limit,
      );

  @override
  Future<Either<Failure, List<Post>>> getTeamPosts(
    String teamId, {
    int limit = 20,
    DateTime? before,
  }) =>
      getHomeFeed(
        mode: 'team',
        targetId: teamId,
        cursorPublishedAt: before,
        limit: limit,
      );

  @override
  Future<Either<Failure, List<Post>>> getBookmarkedPosts({
    int limit = 20,
    DateTime? before,
  }) =>
      getHomeFeed(
        mode: 'saved',
        cursorPublishedAt: before,
        limit: limit,
      );

  @override
  Future<Either<Failure, bool>> togglePostLike(PostId id) async {
    return setPostLike(id, liked: true);
  }

  @override
  Future<Either<Failure, bool>> toggleBookmark(PostId id) async {
    return setPostBookmark(id, bookmarked: true);
  }
}
