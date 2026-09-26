import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/comment.dart';
import '../entities/comment_like_result.dart';

abstract class CommentsRepository {
  /// Fetch keyset-paginated top-level comments for a post.
  Future<Either<Failure, List<Comment>>> getComments(
    String postId, {
    DateTime? cursorCreatedAt,
    String? cursorCommentId,
    int limit = 20,
  });

  /// Fetch keyset-paginated replies for a specific parent comment.
  Future<Either<Failure, List<Comment>>> getCommentReplies(
    String parentCommentId, {
    DateTime? cursorCreatedAt,
    String? cursorCommentId,
    int limit = 20,
  });

  /// Add a new comment or reply to a post.
  Future<Either<Failure, Comment>> addComment({
    required String postId,
    required String text,
    String? parentCommentId,
    List<String> mentionedUserIds = const [],
  });

  /// Delete a comment.
  Future<Either<Failure, Unit>> deleteComment(String commentId);

  /// Desired-state comment like. Sets liked to true or false and returns canonical server state.
  Future<Either<Failure, CommentLikeResult>> setCommentLike(
    String commentId, {
    required bool liked,
  });
}
