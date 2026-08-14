import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../models/post_dto.dart';

/// Talks to Supabase for the `posts` table + `post-media` storage bucket.
/// Returns DTOs, throws raw exceptions. RLS scopes reads/writes.
class PostsRemoteDataSource {
  PostsRemoteDataSource(this._supabase);
  final SupabaseClient _supabase;

  static const _table = 'posts';
  static const _bucket = 'post-media';

  // Embed the author's profile so the feed renders without a second query.
  static const _select =
      '*, author:profiles!author_id(display_name, username, profile_photo_url)';

  String _requireUid() {
    final id = _supabase.auth.currentUser?.id;
    if (id == null) throw UnauthorizedException('Must be signed in');
    return id;
  }

  Future<List<PostDto>> getFeed({required int limit, String filter = 'all', DateTime? before}) async {
    try {
      var q = _supabase.from(_table).select(_select).eq('status', 'active');
      
      if (filter == 'people') {
        q = q.eq('author_context', 'personal');
      } else if (filter == 'teams') {
        q = q.eq('author_context', 'team_manager');
      } else if (filter == 'tournaments') {
        q = q.eq('author_context', 'tournament_organizer');
      } else if (filter == 'matches') {
        q = q.eq('post_type', 'match_announcement');
      }

      if (before != null) q = q.lt('created_at', before.toIso8601String());
      final rows = await q.order('created_at', ascending: false).limit(limit);
      return rows
          .map((r) => PostDto.fromJson(r))
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<List<PostDto>> getByAuthor(
    String authorId, {
    required int limit,
    DateTime? before,
  }) async {
    try {
      var q = _supabase
          .from(_table)
          .select(_select)
          .eq('author_id', authorId)
          .eq('status', 'active');
      if (before != null) q = q.lt('created_at', before.toIso8601String());
      final rows = await q.order('created_at', ascending: false).limit(limit);
      return rows
          .map((r) => PostDto.fromJson(r))
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  /// Insert the post row FIRST (storage RLS `is_post_author` requires the row
  /// to exist before media upload). Returns the row with the author embed.
  Future<PostDto> insertPost(Map<String, dynamic> payload) async {
    try {
      final row = await _supabase
          .from(_table)
          .insert({...payload, 'author_id': _requireUid()})
          .select(_select)
          .single();
      return PostDto.fromJson(row);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  /// Upload each already-resized JPEG to `post-media/<postId>/<i>.jpg`.
  Future<void> uploadMedia(String postId, List<File> files) async {
    try {
      for (var i = 0; i < files.length; i++) {
        await _supabase.storage.from(_bucket).upload(
              '$postId/$i.jpg',
              files[i],
              fileOptions: const FileOptions(
                contentType: 'image/jpeg',
                upsert: true,
              ),
            );
      }
    } on StorageException catch (e) {
      throw ServerException(e.message);
    }
  }

  /// Public URL for a stored object (the bucket is public).
  String publicUrl(String path) =>
      _supabase.storage.from(_bucket).getPublicUrl(path);

  /// Soft-delete (preserve audit trail, per the schema's status posture).
  Future<void> deletePost(String id) async {
    try {
      _requireUid(); // fast explicit failure rather than a silent zero-row RLS no-op
      await _supabase
          .from(_table)
          .update({'status': 'deleted'}).eq('post_id', id);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }
}
