import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../data/datasources/posts_datasource_providers.dart';
import '../../data/repositories/posts_repository_impl.dart';
import '../../domain/entities/pending_post.dart';
import '../../domain/entities/post.dart';
import '../../domain/repositories/posts_repository.dart';

part 'posts_providers.g.dart';

@Riverpod(keepAlive: true)
PostsRepository postsRepository(Ref ref) => PostsRepositoryImpl(
      ref.watch(postsRemoteDataSourceProvider),
      local: ref.watch(postsLocalDataSourceProvider),
    );

/// Emits the local pending uploads/posts created on this device.
@riverpod
Stream<List<PendingPost>> pendingPosts(Ref ref) {
  return ref.watch(postsRepositoryProvider).watchPendingPosts();
}

/// Posts authored by [authorId] (Profile tab / spectator). Throws a
/// [FailureWrapper] on error so the UI renders it via `AsyncError`.
@riverpod
Future<List<Post>> authorPosts(Ref ref, String authorId) async {
  // Watch synchronously before the await (don't chain watch→await).
  final repo = ref.watch(postsRepositoryProvider);
  final result = await repo.getHomeFeed(mode: 'user', targetId: authorId);
  return result.fold((f) => throw FailureWrapper(f), (p) => p);
}

/// Posts authored by or linked to [teamId] (Team Profile Posts tab).
@riverpod
Future<List<Post>> teamPosts(Ref ref, String teamId) async {
  final repo = ref.watch(postsRepositoryProvider);
  final result = await repo.getHomeFeed(mode: 'team', targetId: teamId);
  return result.fold((f) => throw FailureWrapper(f), (p) => p);
}

/// The currently selected feed filter ('all', 'people', 'teams', 'tournaments', 'matches').
@riverpod
class FeedFilter extends _$FeedFilter {
  @override
  String build() => 'all';

  void setFilter(String filter) => state = filter;
}

/// Single post by [postId] for canonical /posts/:postId screen.
@riverpod
Future<Post> postDetail(Ref ref, String postId) async {
  final repo = ref.watch(postsRepositoryProvider);
  final result = await repo.getPost(PostId(postId));
  return result.fold((f) => throw FailureWrapper(f), (p) => p);
}

/// Bookmarked / saved posts.
@riverpod
Future<List<Post>> savedPosts(Ref ref) async {
  final repo = ref.watch(postsRepositoryProvider);
  final result = await repo.getHomeFeed(mode: 'saved');
  return result.fold((f) => throw FailureWrapper(f), (p) => p);
}
