import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../../domain/entities/comment_like_result.dart';
import '../models/comment_dto.dart';

class CommentsRemoteDataSource {
  CommentsRemoteDataSource(this._supabase);
  final SupabaseClient _supabase;

  String _requireUid() {
    final id = _supabase.auth.currentUser?.id;
    if (id == null) throw const UnauthorizedException('Must be signed in');
    return id;
  }

  /// Get keyset-paginated top-level active comments for a post via get_post_comments RPC.
  Future<List<CommentDto>> getComments(
    String postId, {
    DateTime? cursorCreatedAt,
    String? cursorCommentId,
    int limit = 20,
  }) async {
    final response = await _supabase.rpc<dynamic>(
      'get_post_comments',
      params: {
        'p_post_id': postId,
        if (cursorCreatedAt != null)
          'p_cursor_created_at': cursorCreatedAt.toIso8601String(),
        if (cursorCommentId != null) 'p_cursor_comment_id': cursorCommentId,
        'p_limit': limit,
      },
    );

    if (response is List) {
      return response
          .whereType<Map<String, dynamic>>()
          .map((json) => CommentDto.fromJson(json))
          .toList();
    }
    return const [];
  }

  /// Get keyset-paginated replies for a specific parent comment via get_comment_replies RPC.
  Future<List<CommentDto>> getCommentReplies(
    String parentCommentId, {
    DateTime? cursorCreatedAt,
    String? cursorCommentId,
    int limit = 20,
  }) async {
    final response = await _supabase.rpc<dynamic>(
      'get_comment_replies',
      params: {
        'p_parent_comment_id': parentCommentId,
        if (cursorCreatedAt != null)
          'p_cursor_created_at': cursorCreatedAt.toIso8601String(),
        if (cursorCommentId != null) 'p_cursor_comment_id': cursorCommentId,
        'p_limit': limit,
      },
    );

    if (response is List) {
      return response
          .whereType<Map<String, dynamic>>()
          .map((json) => CommentDto.fromJson(json))
          .toList();
    }
    return const [];
  }

  /// Insert a comment/reply row via create_comment command RPC.
  Future<CommentDto> insertComment({
    required String postId,
    required String text,
    String? parentCommentId,
    List<String> mentionedUserIds = const [],
  }) async {
    _requireUid();
    final response = await _supabase.rpc<dynamic>(
      'create_comment',
      params: {
        'p_post_id': postId,
        'p_text': text,
        if (parentCommentId != null) 'p_parent_comment_id': parentCommentId,
        if (mentionedUserIds.isNotEmpty)
          'p_mentioned_user_ids': mentionedUserIds,
      },
    );

    if (response is Map<String, dynamic>) {
      return CommentDto.fromJson(response);
    }
    throw const ServerException('Failed to create comment');
  }

  /// Delete a comment via delete_comment command RPC (either comment author or post author).
  Future<void> deleteComment(String commentId) async {
    _requireUid();
    await _supabase.rpc<dynamic>(
      'delete_comment',
      params: {'p_comment_id': commentId},
    );
  }

  /// Desired-state comment like RPC.
  Future<CommentLikeResult> setCommentLike(
    String commentId, {
    required bool liked,
  }) async {
    _requireUid();
    final response = await _supabase.rpc<dynamic>(
      'set_comment_like',
      params: {
        'p_comment_id': commentId,
        'p_liked': liked,
      },
    );

    if (response is Map<String, dynamic>) {
      return CommentLikeResult(
        commentId: commentId,
        isLiked: response['is_liked'] as bool? ?? liked,
        likesCount: response['likes_count'] as int? ?? 0,
      );
    }
    return CommentLikeResult(commentId: commentId, isLiked: liked, likesCount: 0);
  }
}
