import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../data/datasources/posts_datasource_providers.dart';
import '../../data/repositories/posts_repository_impl.dart';
import '../../domain/entities/post.dart';
import '../../domain/repositories/posts_repository.dart';
import '../../domain/usecases/create_post.dart';
import '../../domain/usecases/delete_post.dart';
import '../../domain/usecases/get_author_posts.dart';
import '../../domain/usecases/get_feed.dart';

part 'posts_providers.g.dart';

@Riverpod(keepAlive: true)
PostsRepository postsRepository(Ref ref) =>
    PostsRepositoryImpl(ref.watch(postsRemoteDataSourceProvider));

@riverpod
GetFeed getFeedUseCase(Ref ref) => GetFeed(ref.watch(postsRepositoryProvider));

@riverpod
GetAuthorPosts getAuthorPostsUseCase(Ref ref) =>
    GetAuthorPosts(ref.watch(postsRepositoryProvider));

@riverpod
CreatePost createPostUseCase(Ref ref) =>
    CreatePost(ref.watch(postsRepositoryProvider));

@riverpod
DeletePost deletePostUseCase(Ref ref) =>
    DeletePost(ref.watch(postsRepositoryProvider));

/// Posts authored by [authorId] (Profile tab / spectator). Throws a
/// [FailureWrapper] on error so the UI renders it via `AsyncError`.
@riverpod
Future<List<Post>> authorPosts(Ref ref, String authorId) async {
  // Watch synchronously before the await (don't chain watch→await).
  final useCase = ref.watch(getAuthorPostsUseCaseProvider);
  final result = await useCase.call(GetAuthorPostsParams(authorId));
  return result.fold((f) => throw FailureWrapper(f), (p) => p);
}
