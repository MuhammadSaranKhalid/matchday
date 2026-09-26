import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../data/datasources/posts_datasource_providers.dart';
import '../../data/repositories/posts_repository_impl.dart';
import '../../domain/entities/pending_post.dart';
import '../../domain/entities/post.dart';
import '../../domain/repositories/post_command_repository.dart';
import '../../domain/repositories/post_read_repository.dart';
import '../../domain/repositories/posts_repository.dart';
import 'post_store_provider.dart';

part 'posts_providers.g.dart';

@Riverpod(keepAlive: true)
PostsRepository postsRepository(Ref ref) => PostsRepositoryImpl(
      ref.watch(postsRemoteDataSourceProvider),
      local: ref.watch(postsLocalDataSourceProvider),
    );

/// CQRS Read Repository Provider.
@Riverpod(keepAlive: true)
PostReadRepository postReadRepository(Ref ref) => ref.watch(postsRepositoryProvider);

/// CQRS Command Repository Provider.
@Riverpod(keepAlive: true)
PostCommandRepository postCommandRepository(Ref ref) => ref.watch(postsRepositoryProvider);

/// Emits the local pending uploads/posts created on this device.
@riverpod
Stream<List<PendingPost>> pendingPosts(Ref ref) {
  return ref.watch(postCommandRepositoryProvider).watchPendingPosts();
}

/// Posts authored by [authorId] (Profile tab / spectator).
/// Populates the L1 PostStore and returns the canonical entities.
@riverpod
Future<List<Post>> authorPosts(Ref ref, String authorId) async {
  final repo = ref.watch(postReadRepositoryProvider);
  final result = await repo.getProfilePosts(
    publisherId: authorId,
    publisherType: PostPublisherType.user,
  );
  return result.fold(
    (f) => throw FailureWrapper(f),
    (posts) {
      ref.read(postStoreProvider.notifier).upsertAll(posts);
      return posts;
    },
  );
}

/// Posts authored by or linked to [teamId] (Team Profile Posts tab).
@riverpod
Future<List<Post>> teamPosts(Ref ref, String teamId) async {
  final repo = ref.watch(postReadRepositoryProvider);
  final result = await repo.getProfilePosts(
    publisherId: teamId,
    publisherType: PostPublisherType.team,
  );
  return result.fold(
    (f) => throw FailureWrapper(f),
    (posts) {
      ref.read(postStoreProvider.notifier).upsertAll(posts);
      return posts;
    },
  );
}

/// The currently selected feed filter ('all', 'people', 'teams', 'tournaments', 'matches').
@riverpod
class FeedFilter extends _$FeedFilter {
  @override
  String build() => 'all';

  void setFilter(String filter) => state = filter;
}

/// Single post by [postId] for canonical /posts/:postId screen.
/// Checks L1 PostStore first, fetches from server on cache miss.
@riverpod
Future<Post> postDetail(Ref ref, String postId) async {
  final cached = ref.read(postStoreProvider)[PostId(postId)];
  if (cached != null) return cached;

  final repo = ref.watch(postReadRepositoryProvider);
  final result = await repo.getPost(PostId(postId));
  return result.fold(
    (f) => throw FailureWrapper(f),
    (post) {
      ref.read(postStoreProvider.notifier).upsert(post);
      return post;
    },
  );
}

/// Bookmarked / saved posts.
@riverpod
Future<List<Post>> savedPosts(Ref ref) async {
  final repo = ref.watch(postReadRepositoryProvider);
  final result = await repo.getSavedPosts();
  return result.fold(
    (f) => throw FailureWrapper(f),
    (posts) {
      ref.read(postStoreProvider.notifier).upsertAll(posts);
      return posts;
    },
  );
}
