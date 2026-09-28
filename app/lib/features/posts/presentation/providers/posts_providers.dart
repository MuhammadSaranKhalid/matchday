import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/datasources/posts_datasource_providers.dart';
import '../../data/repositories/comments_repository_impl.dart';
import '../../data/repositories/post_command_repository_impl.dart';
import '../../data/repositories/post_read_repository_impl.dart';
import '../../domain/entities/pending_post.dart';
import '../../domain/repositories/comments_repository.dart';
import '../../domain/repositories/post_command_repository.dart';
import '../../domain/repositories/post_read_repository.dart';

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


/// The currently selected feed filter ('all', 'people', 'teams', 'tournaments', 'matches').
@riverpod
class FeedFilter extends _$FeedFilter {
  @override
  String build() => 'all';

  void setFilter(String filter) => state = filter;
}

