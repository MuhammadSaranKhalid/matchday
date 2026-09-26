import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/post.dart';
import '../../domain/repositories/post_read_repository.dart';
import '../providers/post_store_provider.dart';
import '../providers/posts_providers.dart';

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
    state = AsyncData([post, ...current]);
  }

  /// Toggle like state on a post in the feed with desired-state RPC.
  /// Updates the normalized [PostStore] so profile, saved, and detail views sync immediately.
  Future<void> toggleLike(PostId postId) async {
    final current = state.value;
    if (current == null) return;

    final store = ref.read(postStoreProvider.notifier);
    final target = store.get(postId) ?? current.firstWhere((p) => p.id == postId, orElse: () => current.first);
    final targetLiked = !target.isLiked;
    final newCount = targetLiked ? target.likesCount + 1 : (target.likesCount > 0 ? target.likesCount - 1 : 0);

    // 1. Mutate normalized PostStore (updates all observing screens)
    store.updatePost(postId, (p) => p.copyWith(isLiked: targetLiked, likesCount: newCount));

    // 2. Update local FeedController list
    final updated = current.map((p) {
      if (p.id == postId) {
        return p.copyWith(isLiked: targetLiked, likesCount: newCount);
      }
      return p;
    }).toList();
    state = AsyncData(updated);

    // 3. Dispatch command to backend
    final repo = ref.read(postCommandRepositoryProvider);
    final result = await repo.setPostLike(postId, liked: targetLiked);

    result.fold(
      (failure) {
        // Rollback on failure
        store.updatePost(postId, (p) => target);
        state = AsyncData(current);
      },
      (_) {},
    );
  }

  /// Toggle bookmark state on a post in the feed with desired-state RPC.
  /// Updates the normalized [PostStore] so profile, saved, and detail views sync immediately.
  Future<void> toggleBookmark(PostId postId) async {
    final current = state.value;
    if (current == null) return;

    final store = ref.read(postStoreProvider.notifier);
    final target = store.get(postId) ?? current.firstWhere((p) => p.id == postId, orElse: () => current.first);
    final targetBookmarked = !target.isBookmarked;

    // 1. Mutate normalized PostStore
    store.updatePost(postId, (p) => p.copyWith(isBookmarked: targetBookmarked));

    // 2. Update local FeedController list
    final updated = current.map((p) {
      if (p.id == postId) {
        return p.copyWith(isBookmarked: targetBookmarked);
      }
      return p;
    }).toList();
    state = AsyncData(updated);

    // 3. Dispatch command to backend
    final repo = ref.read(postCommandRepositoryProvider);
    final result = await repo.setPostBookmark(postId, bookmarked: targetBookmarked);

    result.fold(
      (failure) {
        // Rollback on failure
        store.updatePost(postId, (p) => target);
        state = AsyncData(current);
      },
      (_) {},
    );
  }

  /// Increment comments count on a post when a comment is added.
  void incrementCommentsCount(PostId postId) {
    ref.read(postStoreProvider.notifier).updatePost(
          postId,
          (p) => p.copyWith(commentsCount: p.commentsCount + 1),
        );

    final current = state.value;
    if (current == null) return;

    final updated = current.map((p) {
      if (p.id == postId) {
        return p.copyWith(commentsCount: p.commentsCount + 1);
      }
      return p;
    }).toList();

    state = AsyncData(updated);
  }

  /// Decrement comments count on a post when a comment is deleted or rolls back.
  void decrementCommentsCount(PostId postId) {
    ref.read(postStoreProvider.notifier).updatePost(
          postId,
          (p) => p.copyWith(
            commentsCount: p.commentsCount > 0 ? p.commentsCount - 1 : 0,
          ),
        );

    final current = state.value;
    if (current == null) return;

    final updated = current.map((p) {
      if (p.id == postId) {
        final count = p.commentsCount > 0 ? p.commentsCount - 1 : 0;
        return p.copyWith(commentsCount: count);
      }
      return p;
    }).toList();

    state = AsyncData(updated);
  }
}

