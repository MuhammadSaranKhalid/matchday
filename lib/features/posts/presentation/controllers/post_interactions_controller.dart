import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/post.dart';
import '../../domain/entities/post_like_result.dart';
import '../providers/post_store_provider.dart';
import '../providers/posts_providers.dart';

part 'post_interactions_controller.g.dart';

/// Single unified controller for post interactions (likes, bookmarks, comments count reconciliation).
///
/// Features:
/// 1. Optimistic updates across all surfaces observing [postStoreProvider].
/// 2. In-flight race prevention (serializes rapid taps per post).
/// 3. Reconciles canonical server counts using [PostLikeResult].
@Riverpod(keepAlive: true)
class PostInteractionsController extends _$PostInteractionsController {
  final Set<PostId> _inFlightLikes = {};
  final Set<PostId> _inFlightBookmarks = {};

  @override
  void build() {}

  /// Toggle or set desired like state with optimistic update and race serialization.
  Future<void> toggleLike(PostId postId, {Post? fallback}) async {
    if (_inFlightLikes.contains(postId)) return;

    final store = ref.read(postStoreProvider.notifier);
    var current = store.get(postId);
    if (current == null && fallback != null) {
      store.upsert(fallback);
      current = fallback;
    }
    if (current == null) return;

    final desiredState = !current.isLiked;

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

    _inFlightLikes.add(postId);
    try {
      final repo = ref.read(postCommandRepositoryProvider);
      final result = await repo.setPostLike(postId, liked: desiredState);

      result.fold(
        (failure) {
          // Rollback to original state on failure
          store.updatePost(
            postId,
            (p) => p.copyWith(
              isLiked: current!.isLiked,
              likesCount: current.likesCount,
            ),
          );
        },
        (likeResult) {
          // Reconcile with authoritative server counts
          store.updatePost(
            postId,
            (p) => p.copyWith(
              isLiked: likeResult.isLiked,
              likesCount: likeResult.likesCount,
            ),
          );
        },
      );
    } finally {
      _inFlightLikes.remove(postId);
    }
  }

  /// Toggle or set desired bookmark state with optimistic update and race serialization.
  Future<void> toggleBookmark(PostId postId, {Post? fallback}) async {
    if (_inFlightBookmarks.contains(postId)) return;

    final store = ref.read(postStoreProvider.notifier);
    var current = store.get(postId);
    if (current == null && fallback != null) {
      store.upsert(fallback);
      current = fallback;
    }
    if (current == null) return;

    final desiredState = !current.isBookmarked;

    // 1. Optimistic update
    store.updatePost(
      postId,
      (p) => p.copyWith(isBookmarked: desiredState),
    );

    _inFlightBookmarks.add(postId);
    try {
      final repo = ref.read(postCommandRepositoryProvider);
      final result = await repo.setPostBookmark(postId, bookmarked: desiredState);

      result.fold(
        (failure) {
          // Rollback
          store.updatePost(
            postId,
            (p) => p.copyWith(isBookmarked: current!.isBookmarked),
          );
        },
        (isBookmarked) {
          store.updatePost(
            postId,
            (p) => p.copyWith(isBookmarked: isBookmarked),
          );
        },
      );
    } finally {
      _inFlightBookmarks.remove(postId);
    }
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
