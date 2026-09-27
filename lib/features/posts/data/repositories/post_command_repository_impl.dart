import 'dart:async';
import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/media_variant.dart';
import '../../domain/entities/pending_post.dart';
import '../../domain/entities/post.dart';
import '../../domain/entities/post_draft.dart';
import '../../domain/entities/post_like_result.dart';
import '../../domain/entities/post_media.dart';
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
      final mediaManifest = <Map<String, dynamic>>[];
      for (var i = 0; i < photos.length; i++) {
        mediaManifest.add({
          'position': i,
          'width': photos[i].width,
          'height': photos[i].height,
          'bytes': photos[i].fileSize,
          'mime': photos[i].mimeType,
        });
      }

      final idempotencyKey = (const Uuid()).v4();

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
        visibility: 'public',
        idempotencyKey: idempotencyKey,
        mediaManifest: mediaManifest,
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

    final uncompleted = post.media.where((m) => !m.uploaded).toList();
    if (uncompleted.isNotEmpty) {
      await _local.savePendingPost(
        post.copyWith(status: PendingPostStatus.uploading, errorMessage: null),
      );
      unawaited(_drainStagingUploads(postId, post.media));
    } else {
      // All media were already uploaded, but backend processing stalled or failed
      await _local.savePendingPost(
        post.copyWith(status: PendingPostStatus.publishing, errorMessage: null),
      );
      try {
        final dto = await _remote.getPost(postId);
        if (dto.status == 'active') {
          await acknowledgePublishedLocally(postId);
        }
      } catch (e) {
        await _local.savePendingPost(
          post.copyWith(
            status: PendingPostStatus.failed,
            errorMessage: 'Server processing check failed: $e',
          ),
        );
      }
    }
  }

  @override
  Future<void> discardPendingPost(String postId) async {
    final list = await _local.getPendingPosts();
    final post = list.where((p) => p.postId == postId).firstOrNull;
    if (post != null) {
      // Mark cancelRequested locally first so failed network requests don't publish later
      await _local.savePendingPost(
        post.copyWith(status: PendingPostStatus.cancelRequested),
      );
    }

    try {
      await _remote.abandonPostPublish(postId);
      // Cancellation confirmed by server (or already gone)
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
    } catch (_) {
      // Offline/network failure: keep cancelRequested durable so recovery retries it
    }
  }

  @override
  Future<void> acknowledgePublishedLocally(String postId) async {
    final list = await _local.getPendingPosts();
    final post = list.where((p) => p.postId == postId).firstOrNull;
    if (post != null) {
      for (final m in post.media) {
        if (m.localPath.isNotEmpty) {
          try {
            final f = File(m.localPath);
            if (f.existsSync()) f.deleteSync();
          } catch (_) {}
        }
      }
      await _local.removePendingPost(postId);
    }
  }

  @override
  Future<void> recoverPendingPosts() async {
    final list = await _local.getPendingPosts();
    for (final post in list) {
      if (post.status == PendingPostStatus.cancelRequested) {
        // Retry pending cancellation
        try {
          await _remote.abandonPostPublish(post.postId);
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
          await _local.removePendingPost(post.postId);
        } catch (_) {}
        continue;
      }

      if (post.status == PendingPostStatus.failed) {
        continue;
      }

      final uncompleted = post.media.where((m) => !m.uploaded).toList();
      if (uncompleted.isNotEmpty) {
        unawaited(_drainStagingUploads(post.postId, post.media));
      } else {
        try {
          final dto = await _remote.getPost(post.postId);
          if (dto.status == 'active') {
            await acknowledgePublishedLocally(post.postId);
          }
        } catch (_) {}
      }
    }
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
                  localPath: p.filePath,
                  width: p.width,
                  height: p.height,
                  fileSize: p.fileSize,
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
          (postId) {
            final optimisticMedia = draft.photos.asMap().entries.map((entry) {
              final idx = entry.key;
              final p = entry.value;
              return PostMedia(
                mediaId: 'local_$idx',
                postId: postId,
                position: idx,
                width: p.width,
                height: p.height,
                status: PostMediaStatus.awaitingUpload,
                variants: {
                  1080: MediaVariant(
                    path: p.filePath,
                    url: p.filePath,
                    width: p.width,
                    height: p.height,
                    sizeBytes: p.fileSize,
                    mimeType: 'image/jpeg',
                  ),
                },
              );
            }).toList();

            final post = Post(
              id: PostId(postId),
              createdByUserId: currentUid,
              publisher: PostPublisher(
                id: publisherId,
                type: publisherType,
                displayName: draft.publisher.name ??
                    (publisherType == PostPublisherType.team ? 'Team' : 'User'),
                username: draft.publisher.username,
                photoUrl: draft.publisher.photoUrl,
              ),
              kind: draft.postKind,
              text: postText.value,
              status:
                  publishPhotos.isEmpty ? PostStatus.active : PostStatus.publishing,
              expectedMediaCount: publishPhotos.length,
              media: optimisticMedia,
              createdAt: DateTime.now(),
              publishedAt: publishPhotos.isEmpty ? DateTime.now() : null,
              linkedMatchId: draft.linkedMatchId,
              linkedTournamentId: draft.linkedTournamentId,
              linkedTeamId: draft.linkedTeamId ??
                  (publisherType == PostPublisherType.team ? publisherId : null),
            );

            if (publishPhotos.isNotEmpty) {
              unawaited(_local.getPendingPosts().then((posts) {
                final match = posts.where((p) => p.postId == postId).firstOrNull;
                if (match != null) {
                  _local.savePendingPost(match.copyWith(optimisticPost: post));
                }
              }));
            }

            return post;
          },
        );
      },
    );
  }
}
