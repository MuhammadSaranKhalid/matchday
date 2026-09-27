import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/post.dart';
import '../../domain/repositories/post_read_repository.dart';
import '../providers/post_store_provider.dart';
import '../providers/posts_providers.dart';
import 'post_query_state.dart';

part 'publisher_posts_controller.g.dart';

/// Keyset-paginated controller for publisher-specific posts (User, Team, Tournament).
/// Query membership lives here; normalized post state lives in [PostStore].
@riverpod
class PublisherPostsController extends _$PublisherPostsController {
  static const _pageSize = 20;

  @override
  Future<PostQueryState> build({
    required PostPublisherType publisherType,
    required String publisherId,
  }) async {
    final repo = ref.watch(postReadRepositoryProvider);
    return _fetchInitial(repo);
  }

  Future<PostQueryState> _fetchInitial(PostReadRepository repo) async {
    final result = await repo.getProfilePosts(
      publisherType: publisherType,
      publisherId: publisherId,
      limit: _pageSize,
    );
    return result.fold(
      (f) => throw FailureWrapper(f),
      (page) {
        ref.read(postStoreProvider.notifier).upsertAll(page.posts);
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

    state = AsyncData(current.copyWith(
      isLoadingMore: true,
      loadMoreError: () => null,
    ));

    final result = await ref.read(postReadRepositoryProvider).getProfilePosts(
      publisherType: publisherType,
      publisherId: publisherId,
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

  void removeId(PostId postId) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(
      ids: current.ids.where((id) => id != postId).toList(),
    ));
  }
}
