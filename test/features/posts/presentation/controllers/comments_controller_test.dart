import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:matchday/core/error/failures.dart';
import 'package:matchday/features/posts/domain/entities/comment.dart';
import 'package:matchday/features/posts/domain/entities/comment_like_result.dart';
import 'package:matchday/features/posts/domain/entities/post.dart';
import 'package:matchday/features/posts/domain/repositories/comments_repository.dart';
import 'package:matchday/features/posts/presentation/controllers/comments_controller.dart';
import 'package:matchday/features/posts/presentation/providers/post_store_provider.dart';
import 'package:matchday/features/posts/presentation/providers/posts_providers.dart';
import 'package:mocktail/mocktail.dart';

class _MockCommentsRepo extends Mock implements CommentsRepository {}

void main() {
  late _MockCommentsRepo commentsRepo;
  late ProviderContainer container;

  final sampleParent = Comment(
    id: 'c1',
    postId: 'p1',
    authorId: 'u1',
    text: 'Parent comment',
    likesCount: 10,
    isLiked: false,
    repliesCount: 1,
    createdAt: DateTime(2026, 1, 1),
    replies: [
      Comment(
        id: 'r1',
        postId: 'p1',
        authorId: 'u2',
        parentCommentId: 'c1',
        text: 'Reply comment',
        likesCount: 2,
        isLiked: false,
        createdAt: DateTime(2026, 1, 1, 0, 5),
      ),
    ],
  );

  final samplePost = Post(
    id: const PostId('p1'),
    createdByUserId: 'u1',
    publisher: const PostPublisher(
      id: 'u1',
      type: PostPublisherType.user,
      displayName: 'User 1',
    ),
    kind: PostKind.standard,
    createdAt: DateTime(2026, 1, 1),
    counts: const PostCounts(comments: 5),
  );

  setUp(() {
    commentsRepo = _MockCommentsRepo();
    container = ProviderContainer(
      overrides: [
        commentsRepositoryProvider.overrideWithValue(commentsRepo),
      ],
    );

    // Seed PostStore with post
    container.read(postStoreProvider.notifier).upsert(samplePost);

    when(() => commentsRepo.getComments('p1'))
        .thenAnswer((_) async => Right([sampleParent]));
  });

  tearDown(() {
    container.dispose();
  });

  test('toggleCommentLike on reply uses reply count, not parent count', () async {
    when(() => commentsRepo.setCommentLike('r1', liked: true)).thenAnswer(
      (_) async => const Right(
        CommentLikeResult(commentId: 'r1', isLiked: true, likesCount: 3),
      ),
    );

    final controller = container.read(commentsControllerProvider('p1').notifier);
    await container.read(commentsControllerProvider('p1').future);

    await controller.toggleCommentLike('r1');

    final state = container.read(commentsControllerProvider('p1')).value!;
    final parent = state.first;
    final reply = parent.replies.first;

    // Parent likes count must remain 10
    expect(parent.likesCount, equals(10));
    // Reply likes count must be 3 (2 + 1), NEVER 11 (parent + 1)!
    expect(reply.likesCount, equals(3));
    expect(reply.isLiked, isTrue);
  });

  test('deleteComment on reply decrements parent repliesCount', () async {
    when(() => commentsRepo.deleteComment('r1'))
        .thenAnswer((_) async => const Right(unit));

    final controller = container.read(commentsControllerProvider('p1').notifier);
    await container.read(commentsControllerProvider('p1').future);

    await controller.deleteComment('r1');

    final state = container.read(commentsControllerProvider('p1')).value!;
    final parent = state.first;

    expect(parent.replies, isEmpty);
    expect(parent.repliesCount, equals(0)); // Decremented from 1
  });

  test('addComment failure rolls back comment and decrements post comments count', () async {
    when(() => commentsRepo.addComment(
          postId: 'p1',
          text: 'Failing comment',
          parentCommentId: null,
          mentionedUserIds: const [],
        )).thenAnswer((_) async => const Left(ServerFailure('DB error')));

    final controller = container.read(commentsControllerProvider('p1').notifier);
    await container.read(commentsControllerProvider('p1').future);

    expect(container.read(postStoreProvider)[const PostId('p1')]?.commentsCount, equals(5));

    await controller.addComment('Failing comment');

    final state = container.read(commentsControllerProvider('p1')).value!;
    expect(state.length, equals(1)); // Optimistic comment rolled back
    // Post commentsCount in store must be restored to 5
    expect(container.read(postStoreProvider)[const PostId('p1')]?.commentsCount, equals(5));
  });
}
