import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/comment.dart';

abstract class CommentsRepository {
  /// Fetch all comments for a post, structured as a tree of top-level comments
  /// and their nested replies.
  Future<Either<Failure, List<Comment>>> getComments(String postId);

  /// Add a new comment or reply to a post.
  Future<Either<Failure, Comment>> addComment({
    required String postId,
    required String text,
    String? parentCommentId,
    List<String> mentionedUserIds = const [],
  });

  /// Soft-delete / delete a comment.
  Future<Either<Failure, Unit>> deleteComment(String commentId);

  /// Toggle like state on a comment. Returns updated isLiked boolean.
  Future<Either<Failure, bool>> toggleCommentLike(String commentId);
}
