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
  PostCommandRepositoryImpl(this._remote, {PostsLocalDataSource? local})
    : _local = local ?? PostsLocalDataSourceImpl();

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
          'width': photos[i].width,
          'height': photos[i].height,
          'bytes': photos[i].fileSize,
          'mimeType': photos[i].mimeType,
        });
      }

      final clientCommandId = (const Uuid()).v4();
      final postKindValue = switch (postKind) {
        PostKind.recruitment => 'recruitment',
        PostKind.matchAnnouncement => 'match_announcement',
        PostKind.matchResult => 'match_result',
        PostKind.tournamentUpdate => 'tournament_update',
        PostKind.rosterUpdate => 'roster_update',
        PostKind.milestone => 'milestone',
        _ => 'standard',
      };

      // Persist the command before the first network request. The command ID is
      // the temporary local key until the backend returns the stable post ID.
      await _local.savePendingPost(
        PendingPost(
          postId: clientCommandId,
          clientCommandId: clientCommandId,
          text: text.value,
          media:
              photos
                  .asMap()
                  .entries
                  .map(
                    (entry) => PendingMediaItem(
                      mediaId: '',
                      position: entry.key,
                      localPath: entry.value.localPath,
                      stagingPath: '',
                      width: entry.value.width,
                      height: entry.value.height,
                      bytes: entry.value.fileSize,
                    ),
                  )
                  .toList(),
          createdAt: DateTime.now(),
          publisherType: publisherType.name,
          publisherId: publisherId,
          postKind: postKindValue,
        ),
      );

      final response = await _remote.createPostDraft(
        clientCommandId: clientCommandId,
        publisherType: publisherType.name,
        publisherId: publisherId,
        postKind: postKindValue,
        text: text.value,
        mediaManifest: mediaManifest,
        linkedMatchId: linkedMatchId,
        linkedTournamentId: linkedTournamentId,
        linkedTeamId: linkedTeamId,
      );

      final postId = (response['postId'] ?? response['post_id']) as String;

      // Text-only drafts still require the one publish command.
      if (photos.isEmpty) {
        final pending = PendingPost(
          postId: postId,
          clientCommandId: clientCommandId,
          text: text.value,
          createdAt: DateTime.now(),
          status: PendingPostStatus.publishing,
          publisherType: publisherType.name,
          publisherId: publisherId,
          postKind: postKindValue,
        );
        await _local.removePendingPost(clientCommandId);
        await _local.savePendingPost(pending);
        await _remote.publishPost(postId);
        await _local.removePendingPost(postId);
        return Right(postId);
      }

      await _local.removePendingPost(clientCommandId);

      final serverMedia =
          (response['media'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .toList() ??
          const [];

      final pendingMedia = <PendingMediaItem>[];
      for (var i = 0; i < serverMedia.length; i++) {
        final item = serverMedia[i];
        final position = (item['position'] as num?)?.toInt() ?? i;
        final mediaId = (item['mediaId'] ?? item['media_id']) as String? ?? '';
        final stagingPath =
            (item['stagingPath'] ?? item['staging_path']) as String? ?? '';
        final localPath =
            position < photos.length ? photos[position].localPath : '';

        pendingMedia.add(
          PendingMediaItem(
            mediaId: mediaId,
            position: position,
            localPath: localPath,
            stagingPath: stagingPath,
            uploadToken: item['uploadToken'] as String?,
            width: photos[position].width,
            height: photos[position].height,
            bytes: photos[position].fileSize,
            uploaded: false,
          ),
        );
      }

      // 3. Emit durable local pending post projection for media posts
      final pendingPost = PendingPost(
        postId: postId,
        clientCommandId: clientCommandId,
        text: text.value,
        media: pendingMedia,
        createdAt: DateTime.now(),
        status: PendingPostStatus.uploading,
        progress: 0.0,
        publisherType: publisherType.name,
        publisherId: publisherId,
        postKind: postKindValue,
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
    List<PendingMediaItem> items, {
    bool allowTokenRefresh = true,
  }) async {
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
              throw FileSystemException(
                'Source file missing at ${item.localPath}',
              );
            }

            if (item.stagingPath.isNotEmpty) {
              final token = item.uploadToken;
              if (token == null || token.isEmpty) {
                throw const ServerException('Missing signed upload token');
              }
              await _remote.uploadSignedMedia(
                stagingPath: item.stagingPath,
                uploadToken: token,
                file: file,
              );
            }

            final idx = currentItems.indexWhere(
              (m) => m.mediaId == item.mediaId,
            );
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
                  status:
                      uploadedCount >= total
                          ? PendingPostStatus.publishing
                          : PendingPostStatus.uploading,
                ),
              );
            }
          }),
        );
      }
      await _remote.publishPost(postId);
      unawaited(_reconcileStatus(postId));
    } on StorageException catch (e) {
      if (allowTokenRefresh) {
        final posts = await _local.getPendingPosts();
        final post = posts.where((item) => item.postId == postId).firstOrNull;
        if (post != null) {
          try {
            final refreshed = await _refreshDraft(post);
            await _drainStagingUploads(
              refreshed.postId,
              refreshed.media,
              allowTokenRefresh: false,
            );
            return;
          } catch (_) {}
        }
      }
      await _markUploadFailed(postId, e);
    } catch (e) {
      await _markUploadFailed(postId, e);
    }
  }

  Future<void> _markUploadFailed(String postId, Object error) async {
    final current = await _local.getPendingPosts();
    final existing = current.where((p) => p.postId == postId).firstOrNull;
    if (existing != null) {
      await _local.savePendingPost(
        existing.copyWith(
          status: PendingPostStatus.failed,
          errorMessage: 'Upload failed: $error',
        ),
      );
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
  Future<Either<Failure, PostLikeResult>> setPostLike(
    PostId id, {
    required bool liked,
  }) async {
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
  Future<Either<Failure, bool>> setPostBookmark(
    PostId id, {
    required bool bookmarked,
  }) async {
    try {
      final result = await _remote.setPostBookmark(
        id.value,
        bookmarked: bookmarked,
      );
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
      final refreshed = await _refreshDraft(post);
      unawaited(_drainStagingUploads(refreshed.postId, refreshed.media));
    } else {
      // All media were already uploaded, but backend processing stalled or failed
      await _local.savePendingPost(
        post.copyWith(status: PendingPostStatus.publishing, errorMessage: null),
      );
      try {
        await _remote.publishPost(postId);
        unawaited(_reconcileStatus(postId));
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
      try {
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
      } finally {
        await _local.removePendingPost(postId);
      }
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
      if (post.status == PendingPostStatus.failed) {
        continue;
      }

      if (post.postId == post.clientCommandId) {
        try {
          final refreshed = await _refreshDraft(post);
          if (refreshed.media.isEmpty) {
            await _remote.publishPost(refreshed.postId);
            await acknowledgePublishedLocally(refreshed.postId);
          } else {
            unawaited(_drainStagingUploads(refreshed.postId, refreshed.media));
          }
        } catch (_) {}
        continue;
      }

      final uncompleted = post.media.where((m) => !m.uploaded).toList();
      if (uncompleted.isNotEmpty) {
        try {
          final refreshed = await _refreshDraft(post);
          unawaited(_drainStagingUploads(refreshed.postId, refreshed.media));
        } catch (_) {}
      } else {
        unawaited(_reconcileStatus(post.postId));
      }
    }
  }

  Future<PendingPost> _refreshDraft(PendingPost post) async {
    final response = await _remote.createPostDraft(
      clientCommandId: post.clientCommandId,
      publisherType: post.publisherType,
      publisherId: post.publisherId,
      postKind: post.postKind,
      text: post.text,
      mediaManifest:
          post.media
              .map(
                (item) => {
                  'width': item.width,
                  'height': item.height,
                  'bytes': item.bytes,
                  'mimeType': 'image/jpeg',
                },
              )
              .toList(),
    );
    final stablePostId = (response['postId'] ?? response['post_id']) as String;
    final responseMedia =
        (response['media'] as List).cast<Map<String, dynamic>>();
    final refreshedMedia =
        post.media.map((local) {
          final server = responseMedia.firstWhere(
            (item) => (item['position'] as num).toInt() == local.position,
          );
          return local.copyWith(
            mediaId: (server['mediaId'] ?? server['media_id']) as String,
            stagingPath:
                (server['stagingPath'] ?? server['staging_path']) as String,
            uploadToken: server['uploadToken'] as String,
          );
        }).toList();
    final refreshed = post.copyWith(
      postId: stablePostId,
      media: refreshedMedia,
      status: PendingPostStatus.uploading,
      errorMessage: null,
    );
    if (post.postId != stablePostId) {
      await _local.removePendingPost(post.postId);
    }
    await _local.savePendingPost(refreshed);
    return refreshed;
  }

  Future<void> _reconcileStatus(String postId, {int attempts = 5}) async {
    for (var attempt = 0; attempt < attempts; attempt++) {
      try {
        final status = await _remote.getPostProcessingStatus(postId);
        if (status == 'published') {
          await acknowledgePublishedLocally(postId);
          return;
        }
        if (status == 'failed') {
          final posts = await _local.getPendingPosts();
          final post = posts.where((item) => item.postId == postId).firstOrNull;
          if (post != null) {
            await _local.savePendingPost(
              post.copyWith(
                status: PendingPostStatus.failed,
                errorMessage: 'Image processing failed',
              ),
            );
          }
          return;
        }
      } catch (_) {
        return;
      }
      if (attempt + 1 < attempts) {
        await Future<void>.delayed(const Duration(seconds: 2));
      }
    }
  }

  @override
  Future<Either<Failure, Post>> createPost(PostDraft draft) async {
    final textResult = PostText.create(
      draft.text ?? '',
      hasPhotos: draft.photos.isNotEmpty,
    );

    return textResult.fold((failure) => Left(failure), (postText) async {
      final currentUid = _remote.currentUserId;
      if (currentUid == null) {
        return const Left(AuthFailure('You must be signed in to post.'));
      }

      final publisherType = draft.publisher.type;
      final publisherId =
          (draft.publisher.id != null && draft.publisher.id!.isNotEmpty)
              ? draft.publisher.id!
              : currentUid;

      final publishPhotos =
          draft.photos
              .map(
                (p) => PublishPhoto(
                  localPath: p.filePath,
                  width: p.width,
                  height: p.height,
                  fileSize: p.fileSize,
                ),
              )
              .toList();

      final publishResult = await beginPublishPost(
        publisherType: publisherType,
        publisherId: publisherId,
        postKind: draft.postKind,
        text: postText,
        photos: publishPhotos,
        linkedMatchId: draft.linkedMatchId,
        linkedTournamentId: draft.linkedTournamentId,
        linkedTeamId:
            draft.linkedTeamId ??
            (publisherType == PostPublisherType.team ? publisherId : null),
      );

      return publishResult.map((postId) {
        final optimisticMedia =
            draft.photos.asMap().entries.map((entry) {
              final idx = entry.key;
              final p = entry.value;
              return PostMedia(
                mediaId: 'local_$idx',
                postId: postId,
                position: idx,
                width: p.width,
                height: p.height,
                status: PostMediaStatus.pendingUpload,
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
            displayName:
                draft.publisher.name ??
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
          linkedTeamId:
              draft.linkedTeamId ??
              (publisherType == PostPublisherType.team ? publisherId : null),
        );

        if (publishPhotos.isNotEmpty) {
          unawaited(
            _local.getPendingPosts().then((posts) {
              final match = posts.where((p) => p.postId == postId).firstOrNull;
              if (match != null) {
                _local.savePendingPost(match.copyWith(optimisticPost: post));
              }
            }),
          );
        }

        return post;
      });
    });
  }
}
