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
}
