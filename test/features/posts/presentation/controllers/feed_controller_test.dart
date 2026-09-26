import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:matchday/features/posts/domain/entities/post.dart';
import 'package:matchday/features/posts/domain/repositories/posts_repository.dart';
import 'package:matchday/features/posts/presentation/controllers/feed_controller.dart';
import 'package:matchday/features/posts/presentation/providers/posts_providers.dart';
import 'package:mocktail/mocktail.dart';

class _MockPostsRepository extends Mock implements PostsRepository {}

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
  late _MockPostsRepository repo;
  late ProviderContainer container;

  setUp(() {
    repo = _MockPostsRepository();
    container = ProviderContainer(
      overrides: [
        postsRepositoryProvider.overrideWithValue(repo),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('FeedController (Target Architecture Points 47, 48, 49, 52, 53)', () {
    final now = DateTime.now();
    final p1 = _makePost(id: 'p1', publishedAt: now, likesCount: 5);
    final p2 = _makePost(id: 'p2', publishedAt: now.subtract(const Duration(minutes: 5)));

    test('initial build fetches home feed and sets items', () async {
      when(() => repo.getHomeFeed(
            mode: any(named: 'mode'),
            filter: any(named: 'filter'),
            targetId: any(named: 'targetId'),
            cursorPublishedAt: any(named: 'cursorPublishedAt'),
            cursorPostId: any(named: 'cursorPostId'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => right([p1, p2]));

      final feed = await container.read(feedControllerProvider.future);
      expect(feed.length, equals(2));
      expect(feed.first.id.value, equals('p1'));
      expect(container.read(feedControllerProvider.notifier).hasMore, isFalse);
    });

    test('loadMore paginates using published_at and post_id cursor', () async {
      final initial20 = List.generate(
        20,
        (i) => _makePost(
          id: 'p$i',
          publishedAt: now.subtract(Duration(minutes: i)),
        ),
      );

      when(() => repo.getHomeFeed(
            mode: any(named: 'mode'),
            filter: any(named: 'filter'),
            targetId: any(named: 'targetId'),
            cursorPublishedAt: any(named: 'cursorPublishedAt'),
            cursorPostId: any(named: 'cursorPostId'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => right(initial20));

      final notifier = container.read(feedControllerProvider.notifier);
      await container.read(feedControllerProvider.future);
      expect(notifier.hasMore, isTrue);

      final pMore = _makePost(id: 'pMore', publishedAt: now.subtract(const Duration(minutes: 30)));
      when(() => repo.getHomeFeed(
            mode: any(named: 'mode'),
            filter: any(named: 'filter'),
            targetId: any(named: 'targetId'),
            cursorPublishedAt: any(named: 'cursorPublishedAt'),
            cursorPostId: 'p19',
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => right([pMore]));

      await notifier.loadMore();

      final state = container.read(feedControllerProvider).value!;
      expect(state.length, equals(21));
      expect(state.last.id.value, equals('pMore'));
    });

    test('toggleLike updates state optimistically with desired state and calls repo', () async {
      when(() => repo.getHomeFeed(
            mode: any(named: 'mode'),
            filter: any(named: 'filter'),
            targetId: any(named: 'targetId'),
            cursorPublishedAt: any(named: 'cursorPublishedAt'),
            cursorPostId: any(named: 'cursorPostId'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => right([p1]));

      when(() => repo.setPostLike(const PostId('p1'), liked: true))
          .thenAnswer((_) async => right(true));

      final notifier = container.read(feedControllerProvider.notifier);
      await container.read(feedControllerProvider.future);

      await notifier.toggleLike(const PostId('p1'));

      final post = container.read(feedControllerProvider).value!.first;
      expect(post.viewer.isLiked, isTrue);
      expect(post.counts.likes, equals(6));
      verify(() => repo.setPostLike(const PostId('p1'), liked: true)).called(1);
    });

    test('toggleBookmark updates state optimistically with desired state', () async {
      when(() => repo.getHomeFeed(
            mode: any(named: 'mode'),
            filter: any(named: 'filter'),
            targetId: any(named: 'targetId'),
            cursorPublishedAt: any(named: 'cursorPublishedAt'),
            cursorPostId: any(named: 'cursorPostId'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => right([p1]));

      when(() => repo.setPostBookmark(const PostId('p1'), bookmarked: true))
          .thenAnswer((_) async => right(true));

      final notifier = container.read(feedControllerProvider.notifier);
      await container.read(feedControllerProvider.future);

      await notifier.toggleBookmark(const PostId('p1'));

      final post = container.read(feedControllerProvider).value!.first;
      expect(post.viewer.isBookmarked, isTrue);
      verify(() => repo.setPostBookmark(const PostId('p1'), bookmarked: true)).called(1);
    });

    test('incrementCommentsCount and decrementCommentsCount update post counts', () async {
      when(() => repo.getHomeFeed(
            mode: any(named: 'mode'),
            filter: any(named: 'filter'),
            targetId: any(named: 'targetId'),
            cursorPublishedAt: any(named: 'cursorPublishedAt'),
            cursorPostId: any(named: 'cursorPostId'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => right([p1]));

      final notifier = container.read(feedControllerProvider.notifier);
      await container.read(feedControllerProvider.future);

      notifier.incrementCommentsCount(const PostId('p1'));
      var post = container.read(feedControllerProvider).value!.first;
      expect(post.counts.comments, equals(1));

      notifier.decrementCommentsCount(const PostId('p1'));
      post = container.read(feedControllerProvider).value!.first;
      expect(post.counts.comments, equals(0));
    });
  });
}
