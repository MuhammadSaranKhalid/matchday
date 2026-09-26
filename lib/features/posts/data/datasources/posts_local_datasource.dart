import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../domain/entities/pending_post.dart';

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
      // Ignore corrupted cache file
    }
    _initialized = true;
    _emit();
  }

  void _emit() {
    _controller.add(_memoryCache.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  }

  Future<void> _persist() async {
    try {
      final file = await _getFile();
      final data = _memoryCache.values.map(_toJson).toList();
      await file.writeAsString(jsonEncode(data), flush: true);
    } catch (_) {}
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
  Future<void> savePendingPost(PendingPost post) async {
    await _ensureLoaded();
    _memoryCache[post.postId] = post;
    _emit();
    await _persist();
  }

  @override
  Future<void> removePendingPost(String postId) async {
    await _ensureLoaded();
    _memoryCache.remove(postId);
    _emit();
    await _persist();
  }

  Map<String, dynamic> _toJson(PendingPost p) => {
        'post_id': p.postId,
        'text': p.text,
        'local_media_paths': p.localMediaPaths,
        'created_at': p.createdAt.toIso8601String(),
        'status': p.status.name,
        'progress': p.progress,
        'error_message': p.errorMessage,
      };

  PendingPost _fromJson(Map<String, dynamic> json) => PendingPost(
        postId: json['post_id'] as String,
        text: json['text'] as String?,
        localMediaPaths:
            (json['local_media_paths'] as List?)?.whereType<String>().toList() ??
                const [],
        createdAt: DateTime.parse(json['created_at'] as String),
        status: switch (json['status']) {
          'publishing' => PendingPostStatus.publishing,
          'failed' => PendingPostStatus.failed,
          _ => PendingPostStatus.uploading,
        },
        progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
        errorMessage: json['error_message'] as String?,
      );
}
