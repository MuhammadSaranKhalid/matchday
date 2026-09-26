import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/post.dart';

part 'post_store_provider.g.dart';

/// L1 Session-level normalized Post cache: `Map<PostId, Post>`.
/// All queries (Home Feed, Profile Posts, Saved Posts, Post Detail) point into this store.
/// When interaction state (isLiked, isBookmarked, counts) mutates, every screen viewing the post updates simultaneously.
@Riverpod(keepAlive: true)
class PostStore extends _$PostStore {
  @override
  Map<PostId, Post> build() => const {};

  /// Upsert a single post into the normalized store.
  void upsert(Post post) {
    state = {...state, post.id: post};
  }

  /// Upsert a collection of posts into the normalized store.
  void upsertAll(Iterable<Post> posts) {
    if (posts.isEmpty) return;
    final copy = Map<PostId, Post>.from(state);
    for (final post in posts) {
      copy[post.id] = post;
    }
    state = copy;
  }

  /// Get a post by its ID.
  Post? get(PostId id) => state[id];

  /// Optimistically mutate a post in place.
  void updatePost(PostId id, Post Function(Post current) transform) {
    final current = state[id];
    if (current == null) return;
    state = {...state, id: transform(current)};
  }

  /// Remove a post (e.g. on delete).
  void remove(PostId id) {
    if (!state.containsKey(id)) return;
    final copy = Map<PostId, Post>.from(state)..remove(id);
    state = copy;
  }
}

/// Selector provider to watch an individual Post reactively from the normalized store.
@riverpod
Post? postFromStore(Ref ref, PostId id) {
  final store = ref.watch(postStoreProvider);
  return store[id];
}
