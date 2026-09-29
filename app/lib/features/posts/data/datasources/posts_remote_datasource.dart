import 'dart:io';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../../domain/entities/post_like_result.dart';
import '../models/post_dto.dart';
import 'media_url_factory.dart';

/// Uses NestJS for post commands and Supabase for read projections plus direct
/// signed uploads to private Storage.
class PostsRemoteDataSource {
  PostsRemoteDataSource(
    this._supabase, {
    this.backendBaseUrl = 'http://127.0.0.1:3000',
    http.Client? httpClient,
    String? Function()? accessTokenProvider,
    Future<void> Function(String, String, File)? signedUpload,
  }) : _http = httpClient ?? http.Client(),
       _accessTokenProvider = accessTokenProvider,
       _signedUpload = signedUpload,
       urlFactory = MediaUrlFactory(_supabase);
  final SupabaseClient _supabase;
  final http.Client _http;
  final String backendBaseUrl;
  final String? Function()? _accessTokenProvider;
  final Future<void> Function(String, String, File)? _signedUpload;
  final MediaUrlFactory urlFactory;

  static const _stagingBucket = 'post-media-staging';
  static const _finalBucket = 'post-media';

  String? get currentUserId => _supabase.auth.currentUser?.id;

  String _requireUid() {
    final id = _supabase.auth.currentUser?.id;
    if (id == null) throw const UnauthorizedException('Must be signed in');
    return id;
  }

  /// Calls the consolidated PostgreSQL read model RPC.
  /// Keyset pagination on (published_at, post_id).
  Future<List<PostDto>> getHomeFeed({
    String mode = 'home',
    String filter = 'all',
    String? targetId,
    DateTime? cursorPublishedAt,
    String? cursorPostId,
    int limit = 20,
  }) async {
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
  }

  /// Fetch a single canonical post by ID via get_post_detail RPC.
  Future<PostDto> getPost(String postId) async {
    final response = await _supabase.rpc<dynamic>(
      'get_post_detail',
      params: {'p_post_id': postId},
    );
    if (response is Map<String, dynamic>) {
      return PostDto.fromJson(response);
    }
    throw const ServerException('Post not found');
  }

  /// Keyset-paginated profile posts projection via get_profile_posts RPC.
  Future<List<PostDto>> getProfilePosts({
    required String publisherId,
    String publisherType = 'user',
    DateTime? cursorPublishedAt,
    String? cursorPostId,
    int limit = 20,
  }) async {
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
  }

  /// Keyset-paginated saved/bookmarked posts projection for the current viewer via get_saved_posts RPC.
  Future<List<PostDto>> getSavedPosts({
    DateTime? cursorSavedAt,
    String? cursorPostId,
    int limit = 20,
  }) async {
    _requireUid();
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
  }

  /// Creates (or re-opens) an idempotent backend-owned draft and returns fresh
  /// signed upload tokens for its stable media paths.
  Future<Map<String, dynamic>> createPostDraft({
    required String clientCommandId,
    required String publisherType,
    required String publisherId,
    required String postKind,
    String? text,
    List<Map<String, dynamic>> mediaManifest = const [],
    String? linkedMatchId,
    String? linkedTournamentId,
    String? linkedTeamId,
  }) async {
    final response = await _backend(
      'POST',
      '/api/v1/posts',
      body: {
        'clientCommandId': clientCommandId,
        'publisherType': publisherType,
        'publisherId': publisherId,
        'postKind': postKind,
        if (text != null) 'text': text,
        'media': mediaManifest,
      },
    );
    return response;
  }

  /// Uploads a client-preprocessed JPEG to the private staging bucket (upsert: false).
  Future<void> uploadSignedMedia({
    required String stagingPath,
    required String uploadToken,
    required File file,
  }) async {
    if (_signedUpload != null) {
      await _signedUpload(stagingPath, uploadToken, file);
      return;
    }
    await _supabase.storage
        .from(_stagingBucket)
        .uploadToSignedUrl(
          stagingPath,
          uploadToken,
          file,
          const FileOptions(contentType: 'image/jpeg', upsert: false),
        );
  }

  Future<String> publishPost(String postId) async {
    final response = await _backend('POST', '/api/v1/posts/$postId/publish');
    return response['status'] as String? ?? 'processing';
  }

  Future<String> getPostProcessingStatus(String postId) async {
    final response = await _backend('GET', '/api/v1/posts/$postId/status');
    return response['status'] as String? ?? 'processing';
  }

  Future<Map<String, dynamic>> _backend(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final token =
        _accessTokenProvider?.call() ??
        _supabase.auth.currentSession?.accessToken;
    if (token == null) throw const UnauthorizedException('Must be signed in');
    final uri = Uri.parse(
      '${backendBaseUrl.replaceFirst(RegExp(r'/$'), '')}$path',
    );
    final headers = <String, String>{
      'authorization': 'Bearer $token',
      'content-type': 'application/json',
    };
    final response =
        method == 'GET'
            ? await _http.get(uri, headers: headers)
            : await _http.post(
              uri,
              headers: headers,
              body: body == null ? null : jsonEncode(body),
            );
    final decoded =
        response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message =
          decoded is Map<String, dynamic>
              ? decoded['message']?.toString() ?? 'Backend request failed'
              : 'Backend request failed';
      if (response.statusCode == 401) throw UnauthorizedException(message);
      throw ServerException(message);
    }
    if (decoded is Map<String, dynamic>) return decoded;
    throw const ServerException('Invalid backend response format');
  }

  /// Deletes a staging image using the Storage API.
  Future<void> removeStagingMedia(String stagingPath) async {
    _requireUid();
    await _supabase.storage.from(_stagingBucket).remove([stagingPath]);
  }

  /// Desired-state like: sets liked to true or false deterministically.
  Future<PostLikeResult> setPostLike(
    String postId, {
    required bool liked,
  }) async {
    _requireUid();
    final response = await _supabase.rpc<dynamic>(
      'set_post_like',
      params: {'p_post_id': postId, 'p_liked': liked},
    );
    if (response is Map<String, dynamic>) {
      return PostLikeResult(
        isLiked: response['liked'] as bool? ?? liked,
        likesCount: response['likes_count'] as int? ?? 0,
      );
    }
    return PostLikeResult(isLiked: liked, likesCount: 0);
  }

  /// Desired-state bookmark: sets bookmarked to true or false deterministically.
  Future<bool> setPostBookmark(
    String postId, {
    required bool bookmarked,
  }) async {
    _requireUid();
    final response = await _supabase.rpc<dynamic>(
      'set_post_bookmark',
      params: {'p_post_id': postId, 'p_bookmarked': bookmarked},
    );
    if (response is Map<String, dynamic>) {
      return response['bookmarked'] as bool? ?? bookmarked;
    }
    return bookmarked;
  }

  /// Soft-deletes a post via server RPC delete_post(p_post_id).
  Future<void> deletePost(String postId) async {
    _requireUid();
    await _supabase.rpc<dynamic>('delete_post', params: {'p_post_id': postId});
  }

  String publicUrl(String path) =>
      _supabase.storage.from(_finalBucket).getPublicUrl(path);
}
