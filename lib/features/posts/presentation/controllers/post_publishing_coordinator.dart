import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/datasources/posts_datasource_providers.dart';
import '../../domain/entities/post.dart';
import '../providers/post_store_provider.dart';
import '../providers/posts_providers.dart';

part 'post_publishing_coordinator.g.dart';

/// Application-scoped session coordinator for post publishing, outbox durability,
/// and silent background reconciliation.
/// Keeps feed queries completely decoupled from outbox infrastructure.
@Riverpod(keepAlive: true)
class PostPublishingCoordinator extends _$PostPublishingCoordinator {
  @override
  Future<void> build() async {
    final currentUid = ref.watch(postsRemoteDataSourceProvider).currentUserId;
    if (currentUid == null) return;

    // 1. On startup, restore any pending optimistic post projections into PostStore
    // so in-flight posts never disappear after app restart
    final local = ref.read(postsLocalDataSourceProvider);
    final pendingList = await local.getPendingPosts();
    final store = ref.read(postStoreProvider.notifier);

    for (final p in pendingList) {
      if (p.optimisticPost != null) {
        store.upsert(p.optimisticPost!);
      }
    }

    // 2. Perform outbox startup recovery (resumes staging uploads, retries cancellations)
    unawaited(ref.read(postCommandRepositoryProvider).recoverPendingPosts());

    // 3. Listen to PostStore updates: when any post becomes active, acknowledge it
    // locally to clean up outbox records and cached temporary files
    ref.listen(postStoreProvider, (prev, next) {
      for (final post in next.values) {
        if (post.status == PostStatus.active) {
          ref
              .read(postCommandRepositoryProvider)
              .acknowledgePublishedLocally(post.id.value);
        }
      }
    });
  }
}
