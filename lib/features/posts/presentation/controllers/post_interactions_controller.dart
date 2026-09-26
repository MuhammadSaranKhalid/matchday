import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/post.dart';
import '../../domain/entities/post_like_result.dart';
import '../providers/post_store_provider.dart';
import '../providers/posts_providers.dart';
import 'feed_controller.dart';
import 'saved_posts_controller.dart';

part 'post_interactions_controller.g.dart';

/// Single unified controller for post interactions (likes, bookmarks, comments count reconciliation, deletion).
///
/// Features:
/// 1. Optimistic updates across all surfaces observing [postStoreProvider].
/// 2. Intent coalescing: rapid taps (Like -> Unlike -> Like) queue the latest desired intent
///    so the final server state matches user intent without dropping actions or corrupting counts.
/// 3. Reconciles canonical server counts using [PostLikeResult].
/// 4. Synchronizes query membership: unbookmark immediately evicts the post ID from [savedPostsControllerProvider].
@Riverpod(keepAlive: true)
class PostInteractionsController extends _$PostInteractionsController {
  final Map<PostId, bool> _desiredLikes = {};
  final Map<PostId, int> _likeRevisions = {};
  final Set<PostId> _inFlightLikes = {};

  final Map<PostId, bool> _desiredBookmarks = {};
  final Map<PostId, int> _bookmarkRevisions = {};
  final Set<PostId> _inFlightBookmarks = {};

  @override
  void build() {}

  /// Toggle or set desired like state with optimistic update and intent coalescing.
  Future<void> toggleLike(PostId postId, {Post? fallback}) async {
    final store = ref.read(postStoreProvider.notifier);
    var current = store.get(postId);
    if (current == null && fallback != null) {
      store.upsert(fallback);
      current = fallback;
    }
    if (current == null) return;

    final currentIntent = _desiredLikes[postId] ?? current.isLiked;
    final desiredState = !currentIntent;
    _desiredLikes[postId] = desiredState;
    final rev = (_likeRevisions[postId] ?? 0) + 1;
    _likeRevisions[postId] = rev;

    // 1. Optimistic update in L1 PostStore
    store.updatePost(
      postId,
      (p) => p.copyWith(
        isLiked: desiredState,
        likesCount: desiredState
            ? p.likesCount + 1
            : (p.likesCount > 0 ? p.likesCount - 1 : 0),
      ),
    );

    if (_inFlightLikes.contains(postId)) {
      // Loop already running for this post; it will pick up _desiredLikes[postId]
      return;
    }

    _inFlightLikes.add(postId);
    try {
      final repo = ref.read(postCommandRepositoryProvider);

      while (true) {
        final target = _desiredLikes[postId];
        if (target == null) break;
        final currentRev = _likeRevisions[postId] ?? 0;

        final result = await repo.setPostLike(postId, liked: target);

        // If another tap occurred while in flight, target might differ from latest intent
        if (_desiredLikes[postId] != target) {
          continue;
        }

        result.fold(
          (failure) {
            if (_likeRevisions[postId] == currentRev) {
              _desiredLikes.remove(postId);
              // Rollback optimistic state
              store.updatePost(
                postId,
                (p) => p.copyWith(
                  isLiked: !target,
                  likesCount: !target
                      ? p.likesCount + 1
                      : (p.likesCount > 0 ? p.likesCount - 1 : 0),
                ),
              );
            }
          },
          (likeResult) {
            if (_likeRevisions[postId] == currentRev) {
              _desiredLikes.remove(postId);
              // Reconcile with authoritative server counts
              store.updatePost(
                postId,
                (p) => p.copyWith(
                  isLiked: likeResult.isLiked,
                  likesCount: likeResult.likesCount,
                ),
              );
            }
          },
        );
        break;
      }
    } finally {
      _inFlightLikes.remove(postId);
    }
  }

  /// Toggle or set desired bookmark state with optimistic update and intent coalescing.
  Future<void> toggleBookmark(PostId postId, {Post? fallback}) async {
    final store = ref.read(postStoreProvider.notifier);
    var current = store.get(postId);
    if (current == null && fallback != null) {
      store.upsert(fallback);
      current = fallback;
    }
    if (current == null) return;

    final currentIntent = _desiredBookmarks[postId] ?? current.isBookmarked;
    final desiredState = !currentIntent;
    _desiredBookmarks[postId] = desiredState;
    final rev = (_bookmarkRevisions[postId] ?? 0) + 1;
    _bookmarkRevisions[postId] = rev;

    // 1. Optimistic update
    store.updatePost(
      postId,
      (p) => p.copyWith(isBookmarked: desiredState),
    );

    // 2. Query membership synchronization:
    // If unbookmarking, immediately remove from saved posts query membership
    if (!desiredState) {
      ref.read(savedPostsControllerProvider.notifier).removeId(postId);
    }

    if (_inFlightBookmarks.contains(postId)) return;

    _inFlightBookmarks.add(postId);
    try {
      final repo = ref.read(postCommandRepositoryProvider);

      while (true) {
        final target = _desiredBookmarks[postId];
        if (target == null) break;
        final currentRev = _bookmarkRevisions[postId] ?? 0;

        final result = await repo.setPostBookmark(postId, bookmarked: target);

        if (_desiredBookmarks[postId] != target) {
          continue;
        }

        result.fold(
          (failure) {
            if (_bookmarkRevisions[postId] == currentRev) {
              _desiredBookmarks.remove(postId);
              store.updatePost(
                postId,
                (p) => p.copyWith(isBookmarked: !target),
              );
            }
          },
          (isBookmarked) {
            if (_bookmarkRevisions[postId] == currentRev) {
              _desiredBookmarks.remove(postId);
              store.updatePost(
                postId,
                (p) => p.copyWith(isBookmarked: isBookmarked),
              );
            }
          },
        );
        break;
      }
    } finally {
      _inFlightBookmarks.remove(postId);
    }
  }

  /// Delete post: removes from PostStore and all query memberships.
  Future<void> deletePost(PostId postId) async {
    final repo = ref.read(postCommandRepositoryProvider);
    final result = await repo.deletePost(postId);

    result.fold(
      (failure) => null,
      (_) {
        // Evict from PostStore
        ref.read(postStoreProvider.notifier).remove(postId);
        // Evict from query memberships
        ref.read(feedControllerProvider.notifier).removeId(postId);
        ref.read(savedPostsControllerProvider.notifier).removeId(postId);
      },
    );
  }

  /// Bumps or decrements comments count in the normalized L1 store across all views.
  void updateCommentsCount(PostId postId, int delta) {
    ref.read(postStoreProvider.notifier).updatePost(
      postId,
      (p) => p.copyWith(
        commentsCount: (p.commentsCount + delta).clamp(0, 999999),
      ),
    );
  }
}
