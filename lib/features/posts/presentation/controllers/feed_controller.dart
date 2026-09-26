import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/post.dart';
import '../../domain/repositories/post_read_repository.dart';
import '../providers/post_store_provider.dart';
import '../providers/posts_providers.dart';
import 'post_interactions_controller.dart';
import 'post_query_state.dart';

part 'feed_controller.g.dart';

/// The Home feed — normalized post ID membership ordering with keyset pagination + pull-to-refresh.
/// Post entities live in [PostStore] to ensure unified synchronization across all views.
@riverpod
class FeedController extends _$FeedController {
  static const _pageSize = 20;

  @override
  Future<PostQueryState> build() async {
    final filter = ref.watch(feedFilterProvider);
    final repo = ref.watch(postReadRepositoryProvider);
    return _fetchInitial(repo, filter);
  }

  Future<PostQueryState> _fetchInitial(PostReadRepository repo, String filter) async {
    final result = await repo.getHomeFeed(
      filter: filter,
      cursorPublishedAt: null,
      cursorPostId: null,
      limit: _pageSize,
    );
    return result.fold(
      (f) => throw FailureWrapper(f),
      (page) {
        // Upsert into L1 normalized PostStore
        ref.read(postStoreProvider.notifier).upsertAll(page.posts);

        // Provider-neutral pending post reconciliation:
        // When active posts arrive in the canonical feed, discard matching pending outbox records.
        final commandRepo = ref.read(postCommandRepositoryProvider);
        for (final p in page.posts) {
          commandRepo.discardPendingPost(p.id.value);
        }

        return PostQueryState(
          ids: page.posts.map((p) => p.id).toList(),
          nextCursorPublishedAt: page.nextCursorPublishedAt,
          nextCursorPostId: page.nextCursorPostId,
          hasMore: page.hasMore,
        );
      },
    );
  }

  Future<void> refresh() async {
    final filter = ref.read(feedFilterProvider);
    final current = state.value;
    if (current != null) {
      state = AsyncData(current.copyWith(isRefreshing: true));
    }
    final nextState = await AsyncValue.guard(
      () => _fetchInitial(ref.read(postReadRepositoryProvider), filter),
    );
    if (nextState.hasValue) {
      state = nextState;
    } else if (current != null) {
      state = AsyncData(current.copyWith(isRefreshing: false));
    }
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true, loadMoreError: () => null));
    final filter = ref.read(feedFilterProvider);

    final result = await ref.read(postReadRepositoryProvider).getHomeFeed(
      filter: filter,
      cursorPublishedAt: current.nextCursorPublishedAt,
      cursorPostId: current.nextCursorPostId,
      limit: _pageSize,
    );

    result.fold(
      (f) {
        state = AsyncData(current.copyWith(
          isLoadingMore: false,
          loadMoreError: () => f,
        ));
      },
      (page) {
        ref.read(postStoreProvider.notifier).upsertAll(page.posts);
        final existingIdSet = current.ids.toSet();
        final newIds = page.posts
            .map((p) => p.id)
            .where((id) => !existingIdSet.contains(id))
            .toList();

        state = AsyncData(current.copyWith(
          ids: [...current.ids, ...newIds],
          nextCursorPublishedAt: () => page.nextCursorPublishedAt,
          nextCursorPostId: () => page.nextCursorPostId,
          hasMore: page.hasMore,
          isLoadingMore: false,
        ));
      },
    );
  }

  /// Prepend a freshly created post without a round-trip (optimistic insert).
  void prepend(Post post) {
    ref.read(postStoreProvider.notifier).upsert(post);
    final current = state.value ?? const PostQueryState();
    final updatedIds = [post.id, ...current.ids.where((id) => id != post.id)];
    state = AsyncData(current.copyWith(ids: updatedIds));
  }

  /// Remove post ID from membership (e.g. on post delete).
  void removeId(PostId postId) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(
      ids: current.ids.where((id) => id != postId).toList(),
    ));
  }

  /// Toggle like state on a post in the feed with desired-state RPC.
  Future<void> toggleLike(PostId postId) =>
      ref.read(postInteractionsControllerProvider.notifier).toggleLike(postId);

  /// Toggle bookmark state on a post in the feed with desired-state RPC.
  Future<void> toggleBookmark(PostId postId) =>
      ref.read(postInteractionsControllerProvider.notifier).toggleBookmark(postId);

  /// Increment comments count on a post when a comment is added.
  void incrementCommentsCount(PostId postId) =>
      ref.read(postInteractionsControllerProvider.notifier).updateCommentsCount(postId, 1);

  /// Decrement comments count on a post when a comment is deleted or rolls back.
  void decrementCommentsCount(PostId postId) =>
      ref.read(postInteractionsControllerProvider.notifier).updateCommentsCount(postId, -1);
}
