import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../data/datasources/posts_datasource_providers.dart';
import '../../data/repositories/comments_repository_impl.dart';
import '../../data/repositories/post_command_repository_impl.dart';
import '../../data/repositories/post_read_repository_impl.dart';
import '../../domain/entities/pending_post.dart';
import '../../domain/entities/post.dart';
import '../../domain/repositories/comments_repository.dart';
import '../../domain/repositories/post_command_repository.dart';
import '../../domain/repositories/post_read_repository.dart';
import 'post_store_provider.dart';

part 'posts_providers.g.dart';

/// CQRS Read Repository Provider.
@Riverpod(keepAlive: true)
PostReadRepository postReadRepository(Ref ref) => PostReadRepositoryImpl(
      ref.watch(postsRemoteDataSourceProvider),
    );

/// CQRS Command Repository Provider.
@Riverpod(keepAlive: true)
PostCommandRepository postCommandRepository(Ref ref) => PostCommandRepositoryImpl(
      ref.watch(postsRemoteDataSourceProvider),
      local: ref.watch(postsLocalDataSourceProvider),
    );

/// Comments Repository Provider.
@Riverpod(keepAlive: true)
CommentsRepository commentsRepository(Ref ref) => CommentsRepositoryImpl(
      ref.watch(commentsRemoteDataSourceProvider),
    );

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
    (page) {
      ref.read(postStoreProvider.notifier).upsertAll(page.posts);
      return page.posts;
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
    (page) {
      ref.read(postStoreProvider.notifier).upsertAll(page.posts);
      return page.posts;
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
/// Implements stale-while-revalidate: returns cached Post from PostStore if present,
/// and revalidates in the background if needed.
@riverpod
Future<Post> postDetail(Ref ref, String postId) async {
  final id = PostId(postId);
  final cached = ref.read(postStoreProvider)[id];

  final repo = ref.watch(postReadRepositoryProvider);
  final future = repo.getPost(id).then((result) {
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
    future.ignore();
    return cached;
  }

  return future;
}

/// Bookmarked / saved posts.
@riverpod
Future<List<Post>> savedPosts(Ref ref) async {
  final repo = ref.watch(postReadRepositoryProvider);
  final result = await repo.getSavedPosts();
  return result.fold(
    (f) => throw FailureWrapper(f),
    (page) {
      ref.read(postStoreProvider.notifier).upsertAll(page.posts);
      return page.posts;
    },
  );
}
