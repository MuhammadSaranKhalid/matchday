import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../data/datasources/posts_datasource_providers.dart';
import '../../data/repositories/posts_repository_impl.dart';
import '../../domain/entities/post.dart';
import '../../domain/repositories/posts_repository.dart';

part 'posts_providers.g.dart';

@Riverpod(keepAlive: true)
PostsRepository postsRepository(Ref ref) =>
    PostsRepositoryImpl(ref.watch(postsRemoteDataSourceProvider));

/// Posts authored by [authorId] (Profile tab / spectator). Throws a
/// [FailureWrapper] on error so the UI renders it via `AsyncError`.
@riverpod
Future<List<Post>> authorPosts(Ref ref, String authorId) async {
  // Watch synchronously before the await (don't chain watch→await).
  final repo = ref.watch(postsRepositoryProvider);
  final result = await repo.getAuthorPosts(authorId);
  return result.fold((f) => throw FailureWrapper(f), (p) => p);
}

/// The currently selected feed filter ('all', 'people', 'teams', 'tournaments', 'matches').
@riverpod
class FeedFilter extends _$FeedFilter {
  @override
  String build() => 'all';

  void setFilter(String filter) => state = filter;
}
