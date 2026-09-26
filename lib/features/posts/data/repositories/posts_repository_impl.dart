import 'dart:async';
import 'dart:io';

import 'package:fpdart/fpdart.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/pending_post.dart';
import '../../domain/entities/post.dart';
import '../../domain/entities/post_draft.dart';
import '../../domain/entities/publish_photo.dart';
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
    required List<PublishPhoto> photos,
    String? linkedMatchId,
    String? linkedTournamentId,
    String? linkedTeamId,
  }) async {
    if (photos.length > 4) {
      return const Left(ValidationFailure('A post can have at most 4 photos.'));
    }

    try {
      final mediaItems = <Map<String, dynamic>>[];
      for (var i = 0; i < photos.length; i++) {
        mediaItems.add({
          'position': i,
          'source_width': photos[i].width,
          'source_height': photos[i].height,
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
        expectedMediaCount: photos.length,
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

      final pendingMedia = <PendingMediaItem>[];
      for (var i = 0; i < serverMedia.length; i++) {
        final item = serverMedia[i];
        final position = (item['position'] as num?)?.toInt() ?? i;
        final mediaId = item['media_id'] as String? ?? '';
        final stagingPath = item['staging_path'] as String? ?? '';
        final localPath =
            position < photos.length ? photos[position].localPath : '';

        pendingMedia.add(PendingMediaItem(
          mediaId: mediaId,
          position: position,
          localPath: localPath,
          stagingPath: stagingPath,
          uploaded: false,
        ));
      }

      // 2. Emit durable local pending post projection
      final pendingPost = PendingPost(
        postId: postId,
        text: text.value,
        media: pendingMedia,
        createdAt: DateTime.now(),
        status: photos.isEmpty
            ? PendingPostStatus.publishing
            : PendingPostStatus.uploading,
        progress: 0.0,
      );
      await _local.savePendingPost(pendingPost);

      // 3. Launch background staging uploads (async / decoupled)
      if (pendingMedia.isNotEmpty) {
        unawaited(_drainStagingUploads(postId, pendingMedia));
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
    List<PendingMediaItem> items,
  ) async {
    try {
      final total = items.length;
      var uploadedCount = items.where((m) => m.uploaded).length;
      final currentItems = List<PendingMediaItem>.from(items);

      for (var i = 0; i < currentItems.length; i += 2) {
        final batch = currentItems.sublist(
          i,
          (i + 2 < currentItems.length) ? i + 2 : currentItems.length,
        );

        await Future.wait(
          batch.map((item) async {
            if (item.uploaded) return;

            final file = File(item.localPath);
            if (await file.exists() && item.stagingPath.isNotEmpty) {
              await _remote.uploadStagingMedia(
                stagingPath: item.stagingPath,
                file: file,
              );
              if (item.mediaId.isNotEmpty) {
                await _remote.markPostMediaUploaded(item.mediaId);
              }
            }

            final idx = currentItems.indexWhere((m) => m.mediaId == item.mediaId);
            if (idx != -1) {
              currentItems[idx] = currentItems[idx].copyWith(uploaded: true);
            }
            uploadedCount++;

            final current = await _local.getPendingPosts();
            final existing =
                current.where((p) => p.postId == postId).firstOrNull;
            if (existing != null) {
              await _local.savePendingPost(
                existing.copyWith(
                  media: currentItems,
                  progress: total > 0 ? uploadedCount / total : 1.0,
                  status: uploadedCount >= total
                      ? PendingPostStatus.publishing
                      : PendingPostStatus.uploading,
                ),
              );
            }
          }),
        );
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

    // Re-attempt upload flow using the exact server staging contracts
    final uncompleted = post.media.where((m) => !m.uploaded).toList();
    if (uncompleted.isNotEmpty) {
      unawaited(_drainStagingUploads(postId, post.media));
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

        final publishPhotos = draft.photos
            .map((p) => PublishPhoto(
                  localPath: p.file.path,
                  width: p.width,
                  height: p.height,
                ))
            .toList();

        final publishResult = await beginPublishPost(
          publisherType: publisherType,
          publisherId: publisherId,
          postKind: PostKind.standard,
          text: postText,
          photos: publishPhotos,
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
            status: publishPhotos.isEmpty ? PostStatus.active : PostStatus.publishing,
            expectedMediaCount: publishPhotos.length,
            createdAt: DateTime.now(),
            publishedAt: publishPhotos.isEmpty ? DateTime.now() : null,
            linkedTeamId: draft.authorContext == PostAuthorContext.teamManager
                ? draft.contextEntityId
                : null,
          ),
        );
      },
    );
  }
}
