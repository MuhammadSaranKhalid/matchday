import 'package:equatable/equatable.dart';

import 'post.dart';

/// Explicit modes for the home feed query contract.
enum HomeFeedMode {
  discover,
  following,
}

/// Keyset-paginated page of posts for Home and Profile queries.
class PostPage extends Equatable {
  const PostPage({
    required this.posts,
    this.nextCursorPublishedAt,
    this.nextCursorPostId,
    required this.hasMore,
  });

  final List<Post> posts;
  final DateTime? nextCursorPublishedAt;
  final String? nextCursorPostId;
  final bool hasMore;

  @override
  List<Object?> get props => [posts, nextCursorPublishedAt, nextCursorPostId, hasMore];
}

/// Keyset-paginated page of saved posts ordered by (bookmarks.created_at desc, post_id desc).
class SavedPostsPage extends Equatable {
  const SavedPostsPage({
    required this.posts,
    this.nextCursorSavedAt,
    this.nextCursorPostId,
    required this.hasMore,
  });

  final List<Post> posts;
  final DateTime? nextCursorSavedAt;
  final String? nextCursorPostId;
  final bool hasMore;

  @override
  List<Object?> get props => [posts, nextCursorSavedAt, nextCursorPostId, hasMore];
}
