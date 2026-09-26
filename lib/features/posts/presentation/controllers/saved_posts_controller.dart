import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/post.dart';
import '../../domain/repositories/post_read_repository.dart';
import '../providers/post_store_provider.dart';
import '../providers/posts_providers.dart';
import 'post_query_state.dart';

part 'saved_posts_controller.g.dart';

/// Normalized controller for the Saved / Bookmarked Posts query.
/// Owns membership list of [PostId]s and keyset cursors.
/// Post entities live in [PostStore].
@riverpod
class SavedPostsController extends _$SavedPostsController {
  static const _pageSize = 20;

  @override
  Future<PostQueryState> build() async {
    final repo = ref.watch(postReadRepositoryProvider);
    return _fetchInitial(repo);
  }

  Future<PostQueryState> _fetchInitial(PostReadRepository repo) async {
    final result = await repo.getSavedPosts(limit: _pageSize);
    return result.fold(
      (f) => throw FailureWrapper(f),
      (page) {
        ref.read(postStoreProvider.notifier).upsertAll(page.posts);
        return PostQueryState(
          ids: page.posts.map((p) => p.id).toList(),
          nextCursorSavedAt: page.nextCursorSavedAt,
          nextCursorPostId: page.nextCursorPostId,
          hasMore: page.hasMore,
        );
      },
    );
  }

  Future<void> refresh() async {
    final current = state.value;
    if (current != null) {
      state = AsyncData(current.copyWith(isRefreshing: true));
    }
    final nextState = await AsyncValue.guard(
      () => _fetchInitial(ref.read(postReadRepositoryProvider)),
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

    final result = await ref.read(postReadRepositoryProvider).getSavedPosts(
      cursorSavedAt: current.nextCursorSavedAt,
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
          nextCursorSavedAt: () => page.nextCursorSavedAt,
          nextCursorPostId: () => page.nextCursorPostId,
          hasMore: page.hasMore,
          isLoadingMore: false,
        ));
      },
    );
  }

  /// Remove post ID from membership (e.g. on unbookmark or delete).
  void removeId(PostId postId) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(
      ids: current.ids.where((id) => id != postId).toList(),
    ));
  }
}
