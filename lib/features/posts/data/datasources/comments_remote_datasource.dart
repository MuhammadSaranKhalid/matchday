import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../models/comment_dto.dart';

class CommentsRemoteDataSource {
  CommentsRemoteDataSource(this._supabase);
  final SupabaseClient _supabase;

  static const _table = 'comments';
  static const _likesTable = 'comment_likes';

  // Embed the commenter's profile
  static const _select =
      '*, author:profiles!author_id(display_name, username, profile_photo_url)';

  String _requireUid() {
    final id = _supabase.auth.currentUser?.id;
    if (id == null) throw UnauthorizedException('Must be signed in');
    return id;
  }

  /// Get all active comments for a post, with user's liked status attached.
  Future<List<CommentDto>> getComments(String postId) async {
    try {
      final rows = await _supabase
          .from(_table)
          .select(_select)
          .eq('post_id', postId)
          .eq('status', 'active')
          .order('created_at', ascending: true);

      final currentUid = _supabase.auth.currentUser?.id;
      final likedCommentIds = <String>{};

      if (currentUid != null && rows.isNotEmpty) {
        final commentIds = rows.map((r) => r['comment_id'] as String).toList();
        final likesRows = await _supabase
            .from(_likesTable)
            .select('comment_id')
            .eq('user_id', currentUid)
            .inFilter('comment_id', commentIds);

        for (final r in likesRows) {
          likedCommentIds.add(r['comment_id'] as String);
        }
      }

      return rows.map((r) {
        final id = r['comment_id'] as String;
        final dto = CommentDto.fromJson(r);
        return dto.copyWith(isLiked: likedCommentIds.contains(id));
      }).toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  /// Insert a comment/reply row.
  Future<CommentDto> insertComment({
    required String postId,
    required String text,
    String? parentCommentId,
    List<String> mentionedUserIds = const [],
  }) async {
    try {
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
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  /// Delete a comment (either comment author or post author).
  Future<void> deleteComment(String commentId) async {
    try {
      _requireUid();
      await _supabase.from(_table).delete().eq('comment_id', commentId);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  /// Toggle like state for the current authenticated user on a comment.
  /// Returns `true` if liked, `false` if unliked.
  Future<bool> toggleCommentLike(String commentId) async {
    try {
      final uid = _requireUid();
      final existing = await _supabase
          .from(_likesTable)
          .select('like_id')
          .eq('comment_id', commentId)
          .eq('user_id', uid)
          .maybeSingle();

      if (existing != null) {
        await _supabase
            .from(_likesTable)
            .delete()
            .eq('comment_id', commentId)
            .eq('user_id', uid);
        return false;
      } else {
        await _supabase.from(_likesTable).insert({
          'comment_id': commentId,
          'user_id': uid,
        });
        return true;
      }
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }
}
