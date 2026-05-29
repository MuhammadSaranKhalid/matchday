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

  // build() watches the repository provider (reactive); action methods read it.
  @override
  Future<List<Post>> build() =>
      _fetch(ref.watch(postsRepositoryProvider), before: null);

  Future<List<Post>> _fetch(PostsRepository repo, {DateTime? before}) async {
    final result = await repo.getFeed(limit: _pageSize, before: before);
    return result.fold(
      (f) => throw FailureWrapper(f),
      (posts) {
        _hasMore = posts.length == _pageSize;
        return posts;
      },
    );
  }

  /// Pull-to-refresh: reset to the first page.
  Future<void> refresh() async {
    _hasMore = true;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _fetch(ref.read(postsRepositoryProvider), before: null),
    );
  }

  /// Append the next page (keyset cursor = the oldest loaded post's createdAt).
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || current.isEmpty || !_hasMore) return;
    final more = await _fetch(
      ref.read(postsRepositoryProvider),
      before: current.last.createdAt,
    );
    state = AsyncData([...current, ...more]);
  }

  /// Prepend a freshly created post without a round-trip (optimistic insert).
  void prepend(Post post) {
    final current = state.value ?? const [];
    state = AsyncData([post, ...current]);
  }
}
