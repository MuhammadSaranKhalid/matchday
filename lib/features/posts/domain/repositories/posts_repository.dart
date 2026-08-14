import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/post.dart';
import '../entities/post_draft.dart';

/// Online-only posts repository (no offline cache — same posture as `matches`).
/// Reads are request/response with keyset pagination via [before].
abstract class PostsRepository {
  /// The public feed (active posts, newest first). Pass [before] = the oldest
  /// loaded post's `createdAt` to page further back.
  Future<Either<Failure, List<Post>>> getFeed({int limit, String filter = 'all', DateTime? before});

  /// Posts authored by [authorId], newest first.
  Future<Either<Failure, List<Post>>> getAuthorPosts(
    String authorId, {
    int limit,
    DateTime? before,
  });

  /// Create a post: inserts the row, then uploads any photos to `post-media`.
  Future<Either<Failure, Post>> createPost(PostDraft draft);

  /// Soft-delete a post the current user authored.
  Future<Either<Failure, Unit>> deletePost(PostId id);
}
