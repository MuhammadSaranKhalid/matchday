import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/post.dart';
import '../../domain/repositories/post_read_repository.dart';
import '../providers/post_store_provider.dart';
import '../providers/posts_providers.dart';
import 'post_interactions_controller.dart';

part 'feed_controller.g.dart';

/// The Home feed — newest active posts with keyset pagination + pull-to-refresh.
/// Integrates with the L1 normalized [PostStore] to keep post interactions synchronized across all screens.
@riverpod
class FeedController extends _$FeedController {
  static const _pageSize = 20;

  bool _hasMore = true;
  bool get hasMore => _hasMore;

  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  @override
  Future<List<Post>> build() {
    final filter = ref.watch(feedFilterProvider);
    return _fetch(
      ref.watch(postReadRepositoryProvider),
      filter: filter,
      cursorPublishedAt: null,
      cursorPostId: null,
    );
  }

  Future<List<Post>> _fetch(
    PostReadRepository repo, {
    required String filter,
    DateTime? cursorPublishedAt,
    String? cursorPostId,
  }) async {
    final result = await repo.getHomeFeed(
      filter: filter,
      cursorPublishedAt: cursorPublishedAt,
      cursorPostId: cursorPostId,
      limit: _pageSize,
    );
    return result.fold(
      (f) => throw FailureWrapper(f),
      (posts) {
        _hasMore = posts.length == _pageSize;
        // Upsert into L1 normalized PostStore
        ref.read(postStoreProvider.notifier).upsertAll(posts);

        // Provider-neutral pending post reconciliation:
        // When active posts arrive in the canonical feed, discard matching pending outbox records.
        final commandRepo = ref.read(postCommandRepositoryProvider);
        for (final p in posts) {
          commandRepo.discardPendingPost(p.id.value);
        }
        return posts;
      },
    );
  }

  Future<void> refresh() async {
    _hasMore = true;
    _isLoadingMore = false;
    final filter = ref.read(feedFilterProvider);
    final nextState = await AsyncValue.guard(
      () => _fetch(
        ref.read(postReadRepositoryProvider),
        filter: filter,
        cursorPublishedAt: null,
        cursorPostId: null,
      ),
    );
    if (nextState.hasValue) {
      state = nextState;
    }
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || current.isEmpty || !_hasMore || _isLoadingMore) return;

    _isLoadingMore = true;
    final lastPost = current.last;
    final filter = ref.read(feedFilterProvider);

    try {
      final more = await _fetch(
        ref.read(postReadRepositoryProvider),
        filter: filter,
        cursorPublishedAt: lastPost.publishedAt ?? lastPost.createdAt,
        cursorPostId: lastPost.id.value,
      );
      state = AsyncData([...current, ...more]);
    } finally {
      _isLoadingMore = false;
    }
  }

  /// Prepend a freshly created post without a round-trip (optimistic insert).
  void prepend(Post post) {
    ref.read(postStoreProvider.notifier).upsert(post);
    final current = state.value ?? const [];
    state = AsyncData([post, ...current.where((p) => p.id != post.id)]);
  }

  /// Toggle like state on a post in the feed with desired-state RPC.
  /// Delegates to [PostInteractionsController] for unified optimistic handling and race serialization.
  Future<void> toggleLike(PostId postId) =>
      ref.read(postInteractionsControllerProvider.notifier).toggleLike(postId);

  /// Toggle bookmark state on a post in the feed with desired-state RPC.
  /// Delegates to [PostInteractionsController] for unified optimistic handling and race serialization.
  Future<void> toggleBookmark(PostId postId) =>
      ref.read(postInteractionsControllerProvider.notifier).toggleBookmark(postId);

  /// Increment comments count on a post when a comment is added.
  void incrementCommentsCount(PostId postId) =>
      ref.read(postInteractionsControllerProvider.notifier).updateCommentsCount(postId, 1);

  /// Decrement comments count on a post when a comment is deleted or rolls back.
  void decrementCommentsCount(PostId postId) =>
      ref.read(postInteractionsControllerProvider.notifier).updateCommentsCount(postId, -1);
}

