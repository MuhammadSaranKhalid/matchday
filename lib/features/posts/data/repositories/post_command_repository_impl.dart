import 'dart:async';
import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/pending_post.dart';
import '../../domain/entities/post.dart';
import '../../domain/entities/post_draft.dart';
import '../../domain/entities/post_like_result.dart';
import '../../domain/entities/publish_photo.dart';
import '../../domain/repositories/post_command_repository.dart';
import '../../domain/value_objects/post_text.dart';
import '../datasources/posts_local_datasource.dart';
import '../datasources/posts_remote_datasource.dart';

/// CQRS Command/Write Repository Implementation.
/// Exclusively handles publishing outbox, mutations, state toggles, and deletion.
class PostCommandRepositoryImpl implements PostCommandRepository {
  PostCommandRepositoryImpl(
    this._remote, {
    PostsLocalDataSource? local,
  }) : _local = local ?? PostsLocalDataSourceImpl();

  final PostsRemoteDataSource _remote;
  final PostsLocalDataSource _local;

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

      // 2. Text-only posts are immediately active on server; do not enter outbox
      if (photos.isEmpty) {
        return Right(postId);
      }

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

      // 3. Emit durable local pending post projection for media posts
      final pendingPost = PendingPost(
        postId: postId,
        text: text.value,
        media: pendingMedia,
        createdAt: DateTime.now(),
        status: PendingPostStatus.uploading,
        progress: 0.0,
      );
      await _local.savePendingPost(pendingPost);

      // 4. Launch background staging uploads
      unawaited(_drainStagingUploads(postId, pendingMedia));

      return Right(postId);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on PostgrestException catch (e) {
      return Left(ServerFailure(e.message));
    } on SocketException catch (e) {
      return Left(NetworkFailure(e.message));
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
            if (!await file.exists()) {
              throw FileSystemException('Source file missing at ${item.localPath}');
            }

            if (item.stagingPath.isNotEmpty) {
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
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on PostgrestException catch (e) {
      return Left(ServerFailure(e.message));
    } on SocketException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PostLikeResult>> setPostLike(PostId id, {required bool liked}) async {
    try {
      final result = await _remote.setPostLike(id.value, liked: liked);
      return Right(result);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on PostgrestException catch (e) {
      return Left(ServerFailure(e.message));
    } on SocketException catch (e) {
      return Left(NetworkFailure(e.message));
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
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on PostgrestException catch (e) {
      return Left(ServerFailure(e.message));
    } on SocketException catch (e) {
      return Left(NetworkFailure(e.message));
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

    final uncompleted = post.media.where((m) => !m.uploaded).toList();
    if (uncompleted.isNotEmpty) {
      unawaited(_drainStagingUploads(postId, post.media));
    }
  }

  @override
  Future<void> discardPendingPost(String postId) async {
    final list = await _local.getPendingPosts();
    final post = list.where((p) => p.postId == postId).firstOrNull;
    try {
      await _remote.abandonPostPublish(postId);
    } catch (_) {}
    if (post != null) {
      for (final m in post.media) {
        if (m.stagingPath.isNotEmpty) {
          try {
            await _remote.removeStagingMedia(m.stagingPath);
          } catch (_) {}
        }
        if (m.localPath.isNotEmpty) {
          try {
            final f = File(m.localPath);
            if (f.existsSync()) f.deleteSync();
          } catch (_) {}
        }
      }
    }
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
        final currentUid = _remote.currentUserId;
        if (currentUid == null) {
          return const Left(AuthFailure('You must be signed in to post.'));
        }

        final publisherType = draft.publisher.type;
        final publisherId =
            (draft.publisher.id != null && draft.publisher.id!.isNotEmpty)
                ? draft.publisher.id!
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
          postKind: draft.postKind,
          text: postText,
          photos: publishPhotos,
          linkedMatchId: draft.linkedMatchId,
          linkedTournamentId: draft.linkedTournamentId,
          linkedTeamId: draft.linkedTeamId ??
              (publisherType == PostPublisherType.team ? publisherId : null),
        );

        return publishResult.map(
          (postId) => Post(
            id: PostId(postId),
            createdByUserId: currentUid,
            publisher: PostPublisher(
              id: publisherId,
              type: publisherType,
              displayName: draft.publisher.name ??
                  (publisherType == PostPublisherType.team ? 'Team' : 'User'),
              photoUrl: draft.publisher.photoUrl,
            ),
            kind: draft.postKind,
            text: postText.value,
            status:
                publishPhotos.isEmpty ? PostStatus.active : PostStatus.publishing,
            expectedMediaCount: publishPhotos.length,
            createdAt: DateTime.now(),
            publishedAt: publishPhotos.isEmpty ? DateTime.now() : null,
            linkedMatchId: draft.linkedMatchId,
            linkedTournamentId: draft.linkedTournamentId,
            linkedTeamId: draft.linkedTeamId ??
                (publisherType == PostPublisherType.team ? publisherId : null),
          ),
        );
      },
    );
  }
}
