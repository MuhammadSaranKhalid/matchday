import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:matchday/features/posts/domain/entities/post.dart';
import 'package:matchday/features/posts/domain/entities/post_like_result.dart';
import 'package:matchday/features/posts/domain/entities/post_page.dart';
import 'package:matchday/features/posts/domain/repositories/post_command_repository.dart';
import 'package:matchday/features/posts/domain/repositories/post_read_repository.dart';
import 'package:matchday/features/posts/presentation/controllers/feed_controller.dart';
import 'package:matchday/features/posts/presentation/controllers/post_interactions_controller.dart';
import 'package:matchday/features/posts/presentation/providers/post_store_provider.dart';
import 'package:matchday/features/posts/presentation/providers/posts_providers.dart';
import 'package:mocktail/mocktail.dart';

class _MockPostReadRepository extends Mock implements PostReadRepository {}
class _MockPostCommandRepository extends Mock implements PostCommandRepository {}

Post _makePost({
  required String id,
  required DateTime publishedAt,
  bool isLiked = false,
  int likesCount = 0,
  bool isBookmarked = false,
  int commentsCount = 0,
}) {
  return Post(
    id: PostId(id),
    createdByUserId: 'u1',
    publisher: const PostPublisher(
      type: PostPublisherType.user,
      id: 'u1',
      displayName: 'User 1',
      username: 'user1',
    ),
    kind: PostKind.standard,
    text: 'Test post $id',
    publishedAt: publishedAt,
    createdAt: publishedAt,
    viewer: PostViewerInteractions(
      isLiked: isLiked,
      isBookmarked: isBookmarked,
    ),
    counts: PostCounts(
      likes: likesCount,
      comments: commentsCount,
    ),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(HomeFeedMode.discover);
  });

  late _MockPostReadRepository readRepo;
  late _MockPostCommandRepository commandRepo;
  late ProviderContainer container;

  setUp(() {
    readRepo = _MockPostReadRepository();
    commandRepo = _MockPostCommandRepository();
    when(() => commandRepo.discardPendingPost(any())).thenAnswer((_) async => right(unit));
    container = ProviderContainer(
      overrides: [
        postReadRepositoryProvider.overrideWithValue(readRepo),
        postCommandRepositoryProvider.overrideWithValue(commandRepo),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('FeedController (Normalized CQRS Architecture)', () {
    final now = DateTime.now();
    final p1 = _makePost(id: 'p1', publishedAt: now, likesCount: 5);
    final p2 = _makePost(id: 'p2', publishedAt: now.subtract(const Duration(minutes: 5)));

    test('initial build fetches home feed, populates PostStore and returns query state', () async {
      when(() => readRepo.getHomeFeed(
            mode: any(named: 'mode'),
            filter: any(named: 'filter'),
            cursorPublishedAt: any(named: 'cursorPublishedAt'),
            cursorPostId: any(named: 'cursorPostId'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => right(PostPage(
            posts: [p1, p2],
            nextCursorPublishedAt: p2.publishedAt,
            nextCursorPostId: p2.id.value,
            hasMore: false,
          )));

      final queryState = await container.read(feedControllerProvider.future);
      expect(queryState.ids.length, equals(2));
      expect(queryState.ids.first.value, equals('p1'));
      expect(queryState.hasMore, isFalse);

      // Verify PostStore contains entities
      final store = container.read(postStoreProvider);
      expect(store[const PostId('p1')], isNotNull);
      expect(store[const PostId('p2')], isNotNull);
    });

    test('loadMore paginates using published_at and post_id cursor', () async {
      final initial20 = List.generate(
        20,
        (i) => _makePost(
          id: 'p$i',
          publishedAt: now.subtract(Duration(minutes: i)),
        ),
      );

      when(() => readRepo.getHomeFeed(
            mode: any(named: 'mode'),
            filter: any(named: 'filter'),
            cursorPublishedAt: any(named: 'cursorPublishedAt'),
            cursorPostId: any(named: 'cursorPostId'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => right(PostPage(
            posts: initial20,
            nextCursorPublishedAt: initial20.last.publishedAt,
            nextCursorPostId: initial20.last.id.value,
            hasMore: true,
          )));

      final notifier = container.read(feedControllerProvider.notifier);
      await container.read(feedControllerProvider.future);
      expect(container.read(feedControllerProvider).value!.hasMore, isTrue);

      final pMore = _makePost(id: 'pMore', publishedAt: now.subtract(const Duration(minutes: 30)));
      when(() => readRepo.getHomeFeed(
            mode: any(named: 'mode'),
            filter: any(named: 'filter'),
            cursorPublishedAt: any(named: 'cursorPublishedAt'),
            cursorPostId: 'p19',
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => right(PostPage(
            posts: [pMore],
            nextCursorPublishedAt: pMore.publishedAt,
            nextCursorPostId: pMore.id.value,
            hasMore: false,
          )));

      await notifier.loadMore();

      final state = container.read(feedControllerProvider).value!;
      expect(state.ids.length, equals(21));
      expect(state.ids.last.value, equals('pMore'));
      expect(state.hasMore, isFalse);
    });
  });

  group('PostInteractionsController', () {
    final now = DateTime.now();
    final p1 = _makePost(id: 'p1', publishedAt: now, likesCount: 5);

    test('toggleLike updates state optimistically with desired state and calls repo', () async {
      container.read(postStoreProvider.notifier).upsert(p1);

      when(() => commandRepo.setPostLike(const PostId('p1'), liked: true))
          .thenAnswer((_) async => right(const PostLikeResult(isLiked: true, likesCount: 6)));

      final notifier = container.read(postInteractionsControllerProvider.notifier);
      await notifier.toggleLike(const PostId('p1'));

      final post = container.read(postFromStoreProvider(const PostId('p1')))!;
      expect(post.viewer.isLiked, isTrue);
      expect(post.counts.likes, equals(6));
      verify(() => commandRepo.setPostLike(const PostId('p1'), liked: true)).called(1);
    });

    test('toggleBookmark updates state optimistically and reconciles with server', () async {
      container.read(postStoreProvider.notifier).upsert(p1);

      when(() => commandRepo.setPostBookmark(const PostId('p1'), bookmarked: true))
          .thenAnswer((_) async => right(true));

      final notifier = container.read(postInteractionsControllerProvider.notifier);
      await notifier.toggleBookmark(const PostId('p1'));

      final post = container.read(postFromStoreProvider(const PostId('p1')))!;
      expect(post.viewer.isBookmarked, isTrue);
      verify(() => commandRepo.setPostBookmark(const PostId('p1'), bookmarked: true)).called(1);
    });

    test('deletePost removes post from PostStore', () async {
      container.read(postStoreProvider.notifier).upsert(p1);

      when(() => commandRepo.deletePost(const PostId('p1')))
          .thenAnswer((_) async => right(unit));

      final notifier = container.read(postInteractionsControllerProvider.notifier);
      await notifier.deletePost(const PostId('p1'));

      final post = container.read(postFromStoreProvider(const PostId('p1')));
      expect(post, isNull);
      verify(() => commandRepo.deletePost(const PostId('p1'))).called(1);
    });
  });
}
