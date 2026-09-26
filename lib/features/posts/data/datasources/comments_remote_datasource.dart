import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../../domain/entities/comment_like_result.dart';
import '../models/comment_dto.dart';

class CommentsRemoteDataSource {
  CommentsRemoteDataSource(this._supabase);
  final SupabaseClient _supabase;

  static const _table = 'comments';

  // Embed the commenter's profile
  static const _select =
      '*, author:profiles!author_id(display_name, username, profile_photo_url)';

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

  /// Insert a comment/reply row.
  Future<CommentDto> insertComment({
    required String postId,
    required String text,
    String? parentCommentId,
    List<String> mentionedUserIds = const [],
  }) async {
    final uid = _requireUid();
    final payload = <String, dynamic>{
      'post_id': postId,
      'author_id': uid,
      'text': text,
      if (parentCommentId != null) 'parent_comment_id': parentCommentId,
      if (mentionedUserIds.isNotEmpty) 'mentioned_user_ids': mentionedUserIds,
    };

    final row = await _supabase
        .from(_table)
        .insert(payload)
        .select(_select)
        .single();

    return CommentDto.fromJson(row);
  }

  /// Delete a comment (either comment author or post author).
  Future<void> deleteComment(String commentId) async {
    _requireUid();
    await _supabase.from(_table).delete().eq('comment_id', commentId);
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
