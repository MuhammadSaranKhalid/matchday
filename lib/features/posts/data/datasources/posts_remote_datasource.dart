import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../models/post_dto.dart';
import 'media_url_factory.dart';

/// Talks to Supabase for the `posts` table + `post-media-staging` private storage +
/// consolidated `get_home_feed`, `begin_post_publish`, `set_post_like`, and `set_post_bookmark` RPCs.
class PostsRemoteDataSource {
  PostsRemoteDataSource(this._supabase) : urlFactory = MediaUrlFactory(_supabase);
  final SupabaseClient _supabase;
  final MediaUrlFactory urlFactory;

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

  /// Fetch a single canonical post by ID via get_post_detail RPC.
  Future<PostDto> getPost(String postId) async {
    try {
      final response = await _supabase.rpc<dynamic>(
        'get_post_detail',
        params: {'p_post_id': postId},
      );
      if (response is Map<String, dynamic>) {
        return PostDto.fromJson(response);
      }
      throw ServerException('Post not found');
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  /// Keyset-paginated profile posts projection via get_profile_posts RPC.
  Future<List<PostDto>> getProfilePosts({
    required String publisherId,
    String publisherType = 'user',
    DateTime? cursorPublishedAt,
    String? cursorPostId,
    int limit = 20,
  }) async {
    try {
      final response = await _supabase.rpc<dynamic>(
        'get_profile_posts',
        params: {
          'p_publisher_id': publisherId,
          'p_publisher_type': publisherType,
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

  /// Keyset-paginated saved/bookmarked posts projection for the current viewer via get_saved_posts RPC.
  Future<List<PostDto>> getSavedPosts({
    DateTime? cursorSavedAt,
    String? cursorPostId,
    int limit = 20,
  }) async {
    _requireUid();
    try {
      final response = await _supabase.rpc<dynamic>(
        'get_saved_posts',
        params: {
          if (cursorSavedAt != null)
            'p_cursor_saved_at': cursorSavedAt.toIso8601String(),
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

  /// Uploads a client-preprocessed JPEG to the private staging bucket (upsert: false).
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
              upsert: false,
            ),
          );
    } on StorageException catch (e) {
      if (!e.message.toLowerCase().contains('already exists')) {
        throw ServerException(e.message);
      }
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  /// Informs Supabase that Flutter safely uploaded the staging source.
  /// Server verifies existence in storage and enqueues to post_media_feed PGMQ.
  Future<Map<String, dynamic>> markPostMediaUploaded(String mediaId) async {
    _requireUid();
    try {
      final response = await _supabase.rpc<dynamic>(
        'mark_post_media_uploaded',
        params: {'p_media_id': mediaId},
      );
      if (response is Map<String, dynamic>) {
        return response;
      }
      return {'media_id': mediaId, 'status': 'uploaded'};
    } on PostgrestException catch (e) {
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
}
