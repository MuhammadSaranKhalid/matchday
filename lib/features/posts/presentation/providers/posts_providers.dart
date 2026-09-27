import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/datasources/posts_datasource_providers.dart';
import '../../data/repositories/comments_repository_impl.dart';
import '../../data/repositories/post_command_repository_impl.dart';
import '../../data/repositories/post_read_repository_impl.dart';
import '../../domain/entities/pending_post.dart';
import '../../domain/entities/post.dart';
import '../../domain/repositories/comments_repository.dart';
import '../../domain/repositories/post_command_repository.dart';
import '../../domain/repositories/post_read_repository.dart';
import '../controllers/publisher_posts_controller.dart';
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

/// Returns a failed outbox post if matching [postId] is currently in terminal failure.
@riverpod
PendingPost? failedPendingPost(Ref ref, String postId) {
  final pendingList = ref.watch(pendingPostsProvider).value ?? const [];
  return pendingList
      .where((p) => p.postId == postId && p.status == PendingPostStatus.failed)
      .firstOrNull;
}

/// Startup coordinator that automatically recovers in-flight pending posts.
@riverpod
Future<void> publishRecoveryCoordinator(Ref ref) async {
  final currentUid = ref.watch(postsRemoteDataSourceProvider).currentUserId;
  if (currentUid != null) {
    await ref.read(postCommandRepositoryProvider).recoverPendingPosts();
  }
}

/// Posts authored by [authorId] (Profile tab / spectator).
/// Delegated to [publisherPostsControllerProvider] and returns live reactive projections from [PostStore].
@riverpod
Future<List<Post>> authorPosts(Ref ref, String authorId) async {
  final queryState = await ref.watch(
    publisherPostsControllerProvider(
      publisherType: PostPublisherType.user,
      publisherId: authorId,
    ).future,
  );
  final store = ref.watch(postStoreProvider);
  return queryState.ids.map((id) => store[id]).whereType<Post>().toList();
}

/// Posts authored by or linked to [teamId] (Team Profile Posts tab).
/// Delegated to [publisherPostsControllerProvider] and returns live reactive projections from [PostStore].
@riverpod
Future<List<Post>> teamPosts(Ref ref, String teamId) async {
  final queryState = await ref.watch(
    publisherPostsControllerProvider(
      publisherType: PostPublisherType.team,
      publisherId: teamId,
    ).future,
  );
  final store = ref.watch(postStoreProvider);
  return queryState.ids.map((id) => store[id]).whereType<Post>().toList();
}

/// The currently selected feed filter ('all', 'people', 'teams', 'tournaments', 'matches').
@riverpod
class FeedFilter extends _$FeedFilter {
  @override
  String build() => 'all';

  void setFilter(String filter) => state = filter;
}

