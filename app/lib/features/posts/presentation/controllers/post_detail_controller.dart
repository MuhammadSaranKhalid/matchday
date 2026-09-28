import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/post.dart';
import '../providers/post_store_provider.dart';
import '../providers/posts_providers.dart';

part 'post_detail_controller.g.dart';

/// Single post controller by [postId] for canonical /posts/:postId screen.
/// Implements stale-while-revalidate: returns cached Post from PostStore if present,
/// and revalidates in the background. Explicit refresh() awaits the network response.
@riverpod
class PostDetailController extends _$PostDetailController {
  @override
  Future<Post> build(String postId) async {
    final id = PostId(postId);
    final cached = ref.read(postStoreProvider)[id];

    final repo = ref.watch(postReadRepositoryProvider);
    final fetchFuture = repo.getPost(id).then((result) {
      return result.fold(
        (f) => throw FailureWrapper(f),
        (post) {
          ref.read(postStoreProvider.notifier).upsert(post);
          return post;
        },
      );
    });

    if (cached != null) {
      // Background revalidation without blocking initial paint
      fetchFuture.then((post) {
        state = AsyncData(post);
      }).ignore();
      return cached;
    }

    return fetchFuture;
  }

  /// Forces network revalidation and awaits completion (used by pull-to-refresh).
  Future<void> refresh() async {
    final id = PostId(postId);
    final repo = ref.read(postReadRepositoryProvider);
    final result = await repo.getPost(id);
    result.fold(
      (f) => throw FailureWrapper(f),
      (post) {
        ref.read(postStoreProvider.notifier).upsert(post);
        state = AsyncData(post);
      },
    );
  }
}
