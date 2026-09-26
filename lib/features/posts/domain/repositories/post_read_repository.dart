import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/post.dart';
import '../entities/post_page.dart';

/// CQRS Query/Read Model Repository for Posts.
/// Reads use specialized, keyset-paginated read RPCs with zero mutation logic.
abstract class PostReadRepository {
  /// Fetches home feed with keyset pagination (published_at, post_id).
  Future<Either<Failure, PostPage>> getHomeFeed({
    HomeFeedMode mode = HomeFeedMode.discover,
    String filter = 'all',
    DateTime? cursorPublishedAt,
    String? cursorPostId,
    int limit = 20,
  });

  /// Fetches a user or team's posts with keyset pagination.
  Future<Either<Failure, PostPage>> getProfilePosts({
    required String publisherId,
    PostPublisherType publisherType = PostPublisherType.user,
    DateTime? cursorPublishedAt,
    String? cursorPostId,
    int limit = 20,
  });

  /// Fetches bookmarked posts for the current authenticated viewer.
  Future<Either<Failure, SavedPostsPage>> getSavedPosts({
    DateTime? cursorSavedAt,
    String? cursorPostId,
    int limit = 20,
  });

  /// Fetches a single canonical post by ID.
  Future<Either<Failure, Post>> getPost(PostId id);
}
