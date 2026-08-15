import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/post.dart';
import '../../domain/repositories/posts_repository.dart';
import '../providers/posts_providers.dart';

part 'feed_controller.g.dart';

/// The Home feed — newest active posts with keyset pagination + pull-to-refresh.
@riverpod
class FeedController extends _$FeedController {
  static const _pageSize = 20;

  bool _hasMore = true;
  bool get hasMore => _hasMore;

  @override
  Future<List<Post>> build() {
    final filter = ref.watch(feedFilterProvider);
    return _fetch(ref.watch(postsRepositoryProvider), filter: filter, before: null);
  }

  Future<List<Post>> _fetch(PostsRepository repo, {required String filter, DateTime? before}) async {
    final result = await repo.getFeed(limit: _pageSize, filter: filter, before: before);
    return result.fold(
      (f) => throw FailureWrapper(f),
      (posts) {
        _hasMore = posts.length == _pageSize;
        
        // Aggressive Prefetching: Start downloading images for these posts immediately
        // in the background before the UI ever scrolls to them. This ensures they
        // are instantly available in the local disk cache.
        for (final p in posts) {
          for (final m in p.media) {
            CachedNetworkImageProvider(m.url).resolve(ImageConfiguration.empty);
          }
        }
        
        return posts;
      },
    );
  }

  Future<void> refresh() async {
    _hasMore = true;
    state = const AsyncLoading();
    final filter = ref.read(feedFilterProvider);
    state = await AsyncValue.guard(
      () => _fetch(ref.read(postsRepositoryProvider), filter: filter, before: null),
    );
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || current.isEmpty || !_hasMore) return;
    final filter = ref.read(feedFilterProvider);
    final more = await _fetch(
      ref.read(postsRepositoryProvider),
      filter: filter,
      before: current.last.createdAt,
    );
    state = AsyncData([...current, ...more]);
  }

  /// Prepend a freshly created post without a round-trip (optimistic insert).
  void prepend(Post post) {
    final current = state.value ?? const [];
    state = AsyncData([post, ...current]);
  }

  /// Toggle like state on a post in the feed optimistically.
  Future<void> toggleLike(PostId postId) async {
    final current = state.value;
    if (current == null) return;

    final updated = current.map((p) {
      if (p.id == postId) {
        final newIsLiked = !p.isLiked;
        final newCount = newIsLiked ? p.likesCount + 1 : (p.likesCount > 0 ? p.likesCount - 1 : 0);
        return p.copyWith(isLiked: newIsLiked, likesCount: newCount);
      }
      return p;
    }).toList();

    state = AsyncData(updated);

    final repo = ref.read(postsRepositoryProvider);
    final result = await repo.togglePostLike(postId);

    result.fold(
      (failure) {
        // Rollback on failure
        state = AsyncData(current);
      },
      (_) {},
    );
  }

  /// Toggle bookmark state on a post in the feed optimistically.
  Future<void> toggleBookmark(PostId postId) async {
    final current = state.value;
    if (current == null) return;

    final updated = current.map((p) {
      if (p.id == postId) {
        return p.copyWith(isBookmarked: !p.isBookmarked);
      }
      return p;
    }).toList();

    state = AsyncData(updated);

    final repo = ref.read(postsRepositoryProvider);
    final result = await repo.toggleBookmark(postId);

    result.fold(
      (failure) {
        // Rollback on failure
        state = AsyncData(current);
      },
      (_) {},
    );
  }

  /// Increment comments count on a post when a comment is added.
  void incrementCommentsCount(PostId postId) {
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
}

