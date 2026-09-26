import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../data/datasources/posts_datasource_providers.dart';
import '../../data/repositories/comments_repository_impl.dart';
import '../../domain/entities/comment.dart';
import '../../domain/entities/post.dart';
import '../../domain/repositories/comments_repository.dart';
import 'post_interactions_controller.dart';

part 'comments_controller.g.dart';

@Riverpod(keepAlive: true)
CommentsRepository commentsRepository(Ref ref) =>
    CommentsRepositoryImpl(ref.watch(commentsRemoteDataSourceProvider));

@riverpod
class CommentsController extends _$CommentsController {
  @override
  Future<List<Comment>> build(String postId) async {
    final repo = ref.watch(commentsRepositoryProvider);
    final result = await repo.getComments(postId);
    return result.fold(
      (f) => throw FailureWrapper(f),
      (comments) => comments,
    );
  }

  /// Add a new comment or reply to a post.
  Future<void> addComment(
    String text, {
    String? parentCommentId,
    List<String> mentionedUserIds = const [],
  }) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return;

    final profile = ref.read(myProfileProvider).value;
    final currentList = state.value ?? [];

    // Temporary optimistic comment
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final optimisticComment = Comment(
      id: tempId,
      postId: postId,
      authorId: profile?.userId.value ?? 'current_user',
      parentCommentId: parentCommentId,
      text: cleanText,
      mentionedUserIds: mentionedUserIds,
      createdAt: DateTime.now(),
      authorName: profile?.displayName ?? 'You',
      authorUsername: profile?.username,
      authorPhotoUrl: profile?.avatarUrl,
    );

    if (parentCommentId == null) {
      state = AsyncData([...currentList, optimisticComment]);
    } else {
      state = AsyncData(currentList.map((c) {
        if (c.id == parentCommentId) {
          return c.copyWith(replies: [...c.replies, optimisticComment]);
        }
        return c;
      }).toList());
    }

    final repo = ref.read(commentsRepositoryProvider);
    final result = await repo.addComment(
      postId: postId,
      text: cleanText,
      parentCommentId: parentCommentId,
      mentionedUserIds: mentionedUserIds,
    );

    result.fold(
      (failure) {
        // Rollback on failure
        state = AsyncData(currentList);
        ref
            .read(postInteractionsControllerProvider.notifier)
            .updateCommentsCount(PostId(postId), -1);
      },
      (created) {
        // Replace temp optimistic comment with actual saved comment
        final updatedList = (state.value ?? currentList).map((c) {
          if (parentCommentId == null) {
            if (c.id == tempId) return created;
            return c;
          } else {
            if (c.id == parentCommentId) {
              final newReplies = c.replies.map((r) => r.id == tempId ? created : r).toList();
              return c.copyWith(replies: newReplies);
            }
            return c;
          }
        }).toList();
        state = AsyncData(updatedList);
      },
    );
  }

  /// Toggle like state on a comment (top-level or reply).
  Future<void> toggleCommentLike(String commentId) async {
    final currentList = state.value ?? [];

    Comment? updateComment(Comment c) {
      if (c.id == commentId) {
        final newIsLiked = !c.isLiked;
        final newCount = newIsLiked ? c.likesCount + 1 : (c.likesCount > 0 ? c.likesCount - 1 : 0);
        return c.copyWith(isLiked: newIsLiked, likesCount: newCount);
      }
      final newReplies = c.replies.map((r) {
        if (r.id == commentId) {
          final newIsLiked = !r.isLiked;
          final newCount = newIsLiked ? r.likesCount + 1 : (r.likesCount > 0 ? r.likesCount - 1 : 0);
          return r.copyWith(isLiked: newIsLiked, likesCount: newCount);
        }
        return r;
      }).toList();
      return c.copyWith(replies: newReplies);
    }

    state = AsyncData(currentList.map((c) => updateComment(c)!).toList());

    final repo = ref.read(commentsRepositoryProvider);
    final result = await repo.toggleCommentLike(commentId);

    result.fold(
      (failure) {
        // Rollback on failure
        state = AsyncData(currentList);
      },
      (isLiked) {
        // Confirmed state
      },
    );
  }

  /// Delete a comment.
  Future<void> deleteComment(String commentId) async {
    final currentList = state.value ?? [];

    final updated = currentList
        .where((c) => c.id != commentId)
        .map((c) => c.copyWith(
              replies: c.replies.where((r) => r.id != commentId).toList(),
            ))
        .toList();

    state = AsyncData(updated);
    ref
        .read(postInteractionsControllerProvider.notifier)
        .updateCommentsCount(PostId(postId), -1);

    final repo = ref.read(commentsRepositoryProvider);
    final result = await repo.deleteComment(commentId);

    result.fold(
      (failure) {
        state = AsyncData(currentList);
        ref
            .read(postInteractionsControllerProvider.notifier)
            .updateCommentsCount(PostId(postId), 1);
      },
      (_) {},
    );
  }
}
