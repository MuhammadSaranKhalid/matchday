import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../models/post_dto.dart';

/// Talks to Supabase for the `posts` table + `post-media-staging` private storage +
/// consolidated `get_home_feed`, `begin_post_publish`, `set_post_like`, and `set_post_bookmark` RPCs.
class PostsRemoteDataSource {
  PostsRemoteDataSource(this._supabase);
  final SupabaseClient _supabase;

  static const _stagingBucket = 'post-media-staging';
  static const _finalBucket = 'post-media';

  String? get currentUserId => _supabase.auth.currentUser?.id;

  String _requireUid() {
    final id = _supabase.auth.currentUser?.id;
    if (id == null) throw UnauthorizedException('Must be signed in');
    return id;
  }

  /// Calls the consolidated PostgreSQL read model RPC.
  /// Eliminates multi-query waterfall and applies keyset pagination (published_at, post_id).
  Future<List<PostDto>> getHomeFeed({
    String mode = 'home',
    String filter = 'all',
    String? targetId,
    DateTime? cursorPublishedAt,
    String? cursorPostId,
    int limit = 20,
  }) async {
    try {
      final response = await _supabase.rpc<dynamic>(
        'get_home_feed',
        params: {
          'p_mode': mode,
          'p_filter': filter,
          if (targetId != null) 'p_target_id': targetId,
          if (cursorPublishedAt != null)
            'p_cursor_published_at': cursorPublishedAt.toIso8601String(),
          if (cursorPostId != null) 'p_cursor_post_id': cursorPostId,
          'p_limit': limit,
        },
      );

      if (response is List) {
        return response
            .whereType<Map<String, dynamic>>()
            .map((json) => PostDto.fromJson(json))
            .toList();
      }
      return const [];
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  /// Fetch a single canonical post by ID.
  Future<PostDto> getPost(String postId) async {
    try {
      final list = await getHomeFeed(mode: 'home', limit: 1);
      final match = list.where((p) => p.postId == postId).firstOrNull;
      if (match != null) return match;

      // Fallback query
      final response = await _supabase
          .from('posts')
          .select('*, author:profiles!author_id(display_name, username, profile_photo_url)')
          .eq('post_id', postId)
          .single();

      return PostDto.fromJson(response);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  /// Atomic publishing session reservation.
  Future<Map<String, dynamic>> beginPostPublish({
    required String publisherType,
    required String publisherId,
    required String postKind,
    String? text,
    required int expectedMediaCount,
    List<Map<String, dynamic>> mediaItems = const [],
    String? linkedMatchId,
    String? linkedTournamentId,
    String? linkedTeamId,
  }) async {
    _requireUid();
    try {
      final response = await _supabase.rpc<dynamic>(
        'begin_post_publish',
        params: {
          'p_publisher_type': publisherType,
          'p_publisher_id': publisherId,
          'p_post_kind': postKind,
          'p_text': text,
          'p_expected_media_count': expectedMediaCount,
          'p_media_items': mediaItems,
          if (linkedMatchId != null) 'p_linked_match_id': linkedMatchId,
          if (linkedTournamentId != null)
            'p_linked_tournament_id': linkedTournamentId,
          if (linkedTeamId != null) 'p_linked_team_id': linkedTeamId,
        },
      );

      if (response is Map<String, dynamic>) {
        return response;
      }
      throw ServerException('Invalid begin_post_publish response format');
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  /// Uploads a client-preprocessed JPEG to the private staging bucket.
  Future<void> uploadStagingMedia({
    required String stagingPath,
    required File file,
  }) async {
    _requireUid();
    try {
      await _supabase.storage.from(_stagingBucket).upload(
            stagingPath,
            file,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );
    } on StorageException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  /// Desired-state like: sets liked to true or false deterministically.
  Future<bool> setPostLike(String postId, {required bool liked}) async {
    _requireUid();
    try {
      final response = await _supabase.rpc<dynamic>(
        'set_post_like',
        params: {
          'p_post_id': postId,
          'p_liked': liked,
        },
      );
      if (response is Map<String, dynamic>) {
        return response['liked'] as bool? ?? liked;
      }
      return liked;
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  /// Desired-state bookmark: sets bookmarked to true or false deterministically.
  Future<bool> setPostBookmark(String postId, {required bool bookmarked}) async {
    _requireUid();
    try {
      final response = await _supabase.rpc<dynamic>(
        'set_post_bookmark',
        params: {
          'p_post_id': postId,
          'p_bookmarked': bookmarked,
        },
      );
      if (response is Map<String, dynamic>) {
        return response['bookmarked'] as bool? ?? bookmarked;
      }
      return bookmarked;
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  /// Soft-delete post by marking status = deleted.
  Future<void> deletePost(String postId) async {
    _requireUid();
    try {
      await _supabase
          .from('posts')
          .update({'status': 'deleted', 'updated_at': DateTime.now().toIso8601String()})
          .eq('post_id', postId);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  String publicUrl(String path) =>
      _supabase.storage.from(_finalBucket).getPublicUrl(path);

  // ─── Legacy Compatibility Methods ──────────────────────────────────────────

  Future<List<PostDto>> getFeed({
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

  Future<List<PostDto>> getByAuthor(
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

  Future<List<PostDto>> getByTeam(
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

  Future<List<PostDto>> getBookmarked({
    int limit = 20,
    DateTime? before,
  }) =>
      getHomeFeed(
        mode: 'saved',
        cursorPublishedAt: before,
        limit: limit,
      );
}
