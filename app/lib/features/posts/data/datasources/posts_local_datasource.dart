import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../domain/entities/media_variant.dart';
import '../../domain/entities/pending_post.dart';
import '../../domain/entities/post.dart';
import '../../domain/entities/post_media.dart';

abstract class PostsLocalDataSource {
  Stream<List<PendingPost>> watchPendingPosts();
  Future<List<PendingPost>> getPendingPosts();
  Future<void> savePendingPost(PendingPost post);
  Future<void> removePendingPost(String postId);
}

class PostsLocalDataSourceImpl implements PostsLocalDataSource {
  PostsLocalDataSourceImpl();

  final _controller = StreamController<List<PendingPost>>.broadcast();
  final Map<String, PendingPost> _memoryCache = {};
  bool _initialized = false;
  File? _storageFile;
  Future<void> _writeQueue = Future.value();

  Future<File> _getFile() async {
    if (_storageFile != null) return _storageFile!;
    final dir = await getApplicationDocumentsDirectory();
    _storageFile = File('${dir.path}/matchday_pending_posts.json');
    return _storageFile!;
  }

  Future<void> _ensureLoaded() async {
    if (_initialized) return;
    try {
      final file = await _getFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.isNotEmpty) {
          final list = jsonDecode(content) as List;
          for (final item in list) {
            if (item is Map<String, dynamic>) {
              final post = _fromJson(item);
              _memoryCache[post.postId] = post;
            }
          }
        }
      }
    } catch (_) {
      // Ignore corrupted cache file on read, but log or start fresh
    }
    _initialized = true;
    _emit();
  }

  void _emit() {
    _controller.add(_memoryCache.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  }

  /// Atomic file replacement: writes to .tmp, flushes, and renames.
  Future<void> _persist() async {
    final file = await _getFile();
    final tempFile = File('${file.path}.tmp');
    final data = _memoryCache.values.map(_toJson).toList();
    final jsonStr = jsonEncode(data);
    await tempFile.writeAsString(jsonStr, flush: true);
    await tempFile.rename(file.path);
  }

  Future<void> _enqueue(Future<void> Function() action) {
    final completer = Completer<void>();
    _writeQueue = _writeQueue.whenComplete(() async {
      try {
        await action();
        completer.complete();
      } catch (e, st) {
        completer.completeError(e, st);
      }
    });
    return completer.future;
  }

  @override
  Stream<List<PendingPost>> watchPendingPosts() {
    _ensureLoaded();
    return _controller.stream;
  }

  @override
  Future<List<PendingPost>> getPendingPosts() async {
    await _ensureLoaded();
    return _memoryCache.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<void> savePendingPost(PendingPost post) => _enqueue(() async {
        await _ensureLoaded();
        _memoryCache[post.postId] = post;
        _emit();
        await _persist();
      });

  @override
  Future<void> removePendingPost(String postId) => _enqueue(() async {
        await _ensureLoaded();
        _memoryCache.remove(postId);
        _emit();
        await _persist();
      });

  Map<String, dynamic> _toJson(PendingPost p) => {
        'post_id': p.postId,
        'text': p.text,
        'media': p.media
            .map((m) => {
                  'media_id': m.mediaId,
                  'position': m.position,
                  'local_path': m.localPath,
                  'staging_path': m.stagingPath,
                  'uploaded': m.uploaded,
                })
            .toList(),
        'created_at': p.createdAt.toIso8601String(),
        'status': p.status.name,
        'progress': p.progress,
        'error_message': p.errorMessage,
        'idempotency_key': p.idempotencyKey,
        'optimistic_post':
            p.optimisticPost != null ? _postToJson(p.optimisticPost!) : null,
      };

  PendingPost _fromJson(Map<String, dynamic> json) {
    final rawMedia = json['media'] as List?;
    final media = rawMedia != null
        ? rawMedia
            .whereType<Map<String, dynamic>>()
            .map((m) => PendingMediaItem(
                  mediaId: m['media_id'] as String? ?? '',
                  position: (m['position'] as num?)?.toInt() ?? 0,
                  localPath: m['local_path'] as String? ?? '',
                  stagingPath: m['staging_path'] as String? ?? '',
                  uploaded: m['uploaded'] as bool? ?? false,
                ))
            .toList()
        : const <PendingMediaItem>[];

    return PendingPost(
      postId: json['post_id'] as String,
      text: json['text'] as String?,
      media: media,
      createdAt: DateTime.parse(json['created_at'] as String),
      status: switch (json['status']) {
        'publishing' => PendingPostStatus.publishing,
        'failed' => PendingPostStatus.failed,
        'cancelRequested' || 'cancel_requested' =>
          PendingPostStatus.cancelRequested,
        _ => PendingPostStatus.uploading,
      },
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      errorMessage: json['error_message'] as String?,
      idempotencyKey: json['idempotency_key'] as String?,
      optimisticPost: _postFromJson(json['optimistic_post'] as Map<String, dynamic>?),
    );
  }

  Map<String, dynamic> _postToJson(Post p) => {
        'id': p.id.value,
        'created_by_user_id': p.createdByUserId,
        'publisher': {
          'id': p.publisher.id,
          'type': p.publisher.type.name,
          'display_name': p.publisher.displayName,
          'username': p.publisher.username,
          'photo_url': p.publisher.photoUrl,
        },
        'kind': p.kind.name,
        'text': p.text,
        'visibility': p.visibility.name,
        'status': p.status.name,
        'expected_media_count': p.expectedMediaCount,
        'media': p.media
            .map((m) => {
                  'media_id': m.mediaId,
                  'position': m.position,
                  'width': m.width,
                  'height': m.height,
                  'variants': {
                    for (final v in m.variants.entries)
                      v.key.toString(): {
                        'url': v.value.url,
                        'path': v.value.path,
                        'width': v.value.width,
                        'height': v.value.height,
                        'size_bytes': v.value.sizeBytes,
                        'mime_type': v.value.mimeType,
                      }
                  }
                })
            .toList(),
        'created_at': p.createdAt.toIso8601String(),
        'linked_match_id': p.linkedMatchId,
        'linked_tournament_id': p.linkedTournamentId,
        'linked_team_id': p.linkedTeamId,
      };

  Post? _postFromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final pubMap = json['publisher'] as Map<String, dynamic>? ?? {};
    final publisher = PostPublisher(
      id: pubMap['id'] as String? ?? '',
      type: switch (pubMap['type']) {
        'team' => PostPublisherType.team,
        'tournament' => PostPublisherType.tournament,
        _ => PostPublisherType.user,
      },
      displayName: pubMap['display_name'] as String? ?? '',
      username: pubMap['username'] as String?,
      photoUrl: pubMap['photo_url'] as String?,
    );

    final rawMedia = json['media'] as List?;
    final media = rawMedia != null
        ? rawMedia.whereType<Map<String, dynamic>>().map((m) {
            final rawVars = m['variants'] as Map<String, dynamic>? ?? {};
            final variants = <int, MediaVariant>{};
            for (final entry in rawVars.entries) {
              final w = int.tryParse(entry.key);
              final vMap = entry.value as Map<String, dynamic>?;
              if (w != null && vMap != null) {
                variants[w] = MediaVariant(
                  url: vMap['url'] as String? ?? '',
                  path: vMap['path'] as String? ?? '',
                  width: (vMap['width'] as num?)?.toInt() ?? 0,
                  height: (vMap['height'] as num?)?.toInt() ?? 0,
                  sizeBytes: (vMap['size_bytes'] as num?)?.toInt() ?? 0,
                  mimeType: vMap['mime_type'] as String? ?? 'image/jpeg',
                );
              }
            }
            return PostMedia(
              mediaId: m['media_id'] as String? ?? '',
              postId: json['id'] as String? ?? '',
              position: (m['position'] as num?)?.toInt() ?? 0,
              width: (m['width'] as num?)?.toInt() ?? 0,
              height: (m['height'] as num?)?.toInt() ?? 0,
              variants: variants,
            );
          }).toList()
        : const <PostMedia>[];

    final rawKind = json['kind'] ?? json['post_kind'];
    return Post(
      id: PostId(json['id'] as String),
      createdByUserId: json['created_by_user_id'] as String? ?? '',
      publisher: publisher,
      kind: switch (rawKind) {
        'recruitment' => PostKind.recruitment,
        'matchAnnouncement' => PostKind.matchAnnouncement,
        'matchResult' => PostKind.matchResult,
        'tournamentUpdate' => PostKind.tournamentUpdate,
        'rosterUpdate' => PostKind.rosterUpdate,
        'milestone' => PostKind.milestone,
        _ => PostKind.standard,
      },
      text: json['text'] as String?,
      visibility: switch (json['visibility']) {
        'followersOnly' => PostVisibility.followersOnly,
        'private' => PostVisibility.private,
        _ => PostVisibility.public,
      },
      status: switch (json['status']) {
        'active' => PostStatus.active,
        'hidden' => PostStatus.hidden,
        'reported' => PostStatus.reported,
        'deleted' => PostStatus.deleted,
        _ => PostStatus.publishing,
      },
      expectedMediaCount: (json['expected_media_count'] as num?)?.toInt() ?? 0,
      media: media,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      linkedMatchId: json['linked_match_id'] as String?,
      linkedTournamentId: json['linked_tournament_id'] as String?,
      linkedTeamId: json['linked_team_id'] as String?,
    );
  }
}
