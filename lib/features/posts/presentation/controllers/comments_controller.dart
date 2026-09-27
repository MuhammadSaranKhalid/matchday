import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../domain/entities/comment.dart';
import '../../domain/entities/post.dart';
import '../providers/posts_providers.dart';
import 'post_interactions_controller.dart';

part 'comments_controller.g.dart';

@riverpod
class CommentsController extends _$CommentsController {
  @override
  Future<List<Comment>> build(String postId) async {
    final repo = ref.watch(commentsRepositoryProvider);
    final result = await repo.getComments(postId);
    return result.fold(
      (f) => throw FailureWrapper(f),
      (comments) {
        if (comments.length < 20) {
          _hasMore = false;
        }
        return comments;
      },
    );
  }

  bool _hasMore = true;
  bool _isLoadingMore = false;
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  /// Loads the next page of top-level comments using keyset cursor pagination.
  Future<void> loadMoreComments() async {
    final currentList = state.value;
    if (currentList == null || currentList.isEmpty || !_hasMore || _isLoadingMore) {
      return;
    }

    _isLoadingMore = true;
    final last = currentList.last;
    final repo = ref.read(commentsRepositoryProvider);
    final result = await repo.getComments(
      postId,
      cursorCreatedAt: last.createdAt,
      cursorCommentId: last.id,
      limit: 20,
    );

    result.fold(
      (f) {
        _isLoadingMore = false;
      },
      (newComments) {
        _isLoadingMore = false;
        if (newComments.isEmpty) {
          _hasMore = false;
          return;
        }
        if (newComments.length < 20) {
          _hasMore = false;
        }
        final existingIds = currentList.map((c) => c.id).toSet();
        final filtered =
            newComments.where((c) => !existingIds.contains(c.id)).toList();
        state = AsyncData([...currentList, ...filtered]);
      },
    );
  }

  /// Loads replies on demand for an expanded parent comment thread.
  Future<void> loadReplies(String parentCommentId) async {
    final repo = ref.read(commentsRepositoryProvider);
    final result = await repo.getCommentReplies(parentCommentId);
    result.fold(
      (f) => null,
      (replies) {
        final currentList = state.value ?? [];
        state = AsyncData(currentList.map((c) {
          if (c.id == parentCommentId) {
            return c.copyWith(replies: replies);
          }
          return c;
        }).toList());
      },
    );
  }

  /// Loads additional replies beyond the initial page for a thread.
  Future<void> loadMoreReplies(String parentCommentId) async {
    final currentList = state.value;
    if (currentList == null) return;
    final parent = currentList.where((c) => c.id == parentCommentId).firstOrNull;
    if (parent == null || parent.replies.isEmpty) {
      return loadReplies(parentCommentId);
    }

    final lastReply = parent.replies.last;
    final repo = ref.read(commentsRepositoryProvider);
    final result = await repo.getCommentReplies(
      parentCommentId,
      cursorCreatedAt: lastReply.createdAt,
      cursorCommentId: lastReply.id,
      limit: 20,
    );

    result.fold(
      (f) => null,
      (newReplies) {
        if (newReplies.isEmpty) return;
        final existingReplyIds = parent.replies.map((r) => r.id).toSet();
        final filtered =
            newReplies.where((r) => !existingReplyIds.contains(r.id)).toList();
        if (filtered.isEmpty) return;

        state = AsyncData((state.value ?? currentList).map((c) {
          if (c.id == parentCommentId) {
            return c.copyWith(replies: [...c.replies, ...filtered]);
          }
          return c;
        }).toList());
      },
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
      state = AsyncData([optimisticComment, ...currentList]);
    } else {
      state = AsyncData(currentList.map((c) {
        if (c.id == parentCommentId) {
          return c.copyWith(
            replies: [...c.replies, optimisticComment],
            repliesCount: c.repliesCount + 1,
          );
        }
        return c;
      }).toList());
    }

    // Encapsulate post comment count increment inside controller
    ref
        .read(postInteractionsControllerProvider.notifier)
        .updateCommentsCount(PostId(postId), 1);

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
              final newReplies =
                  c.replies.map((r) => r.id == tempId ? created : r).toList();
              return c.copyWith(replies: newReplies);
            }
            return c;
          }
        }).toList();
        state = AsyncData(updatedList);
      },
    );
  }

  /// Toggle like state on a comment with desired-state RPC and count reconciliation.
  Future<void> toggleCommentLike(String commentId) async {
    final currentList = state.value ?? [];

    Comment? target;
    for (final c in currentList) {
      if (c.id == commentId) {
        target = c;
        break;
      }
      for (final r in c.replies) {
        if (r.id == commentId) {
          target = r;
          break;
        }
      }
    }
    if (target == null) return;

    final desiredLiked = !target.isLiked;
    final newCount = desiredLiked
        ? target.likesCount + 1
        : (target.likesCount > 0 ? target.likesCount - 1 : 0);

    Comment updateComment(Comment c, bool liked, int count) {
      if (c.id == commentId) {
        return c.copyWith(isLiked: liked, likesCount: count);
      }
      final newReplies = c.replies.map((r) {
        if (r.id == commentId) {
          return r.copyWith(isLiked: liked, likesCount: count);
        }
        return r;
      }).toList();
      return c.copyWith(replies: newReplies);
    }

    // Optimistic flip using target's own count
    state = AsyncData(
      currentList.map((c) => updateComment(c, desiredLiked, newCount)).toList(),
    );

    final repo = ref.read(commentsRepositoryProvider);
    final result = await repo.setCommentLike(commentId, liked: desiredLiked);

    result.fold(
      (failure) {
        // Rollback
        state = AsyncData(currentList);
      },
      (likeResult) {
        // Reconcile with authoritative server counts
        final updated = (state.value ?? currentList).map((c) {
          return updateComment(c, likeResult.isLiked, likeResult.likesCount);
        }).toList();
        state = AsyncData(updated);
      },
    );
  }

  /// Delete a comment.
  Future<void> deleteComment(String commentId) async {
    final currentList = state.value ?? [];

    final updated = currentList
        .where((c) => c.id != commentId)
        .map((c) {
          final isReply = c.replies.any((r) => r.id == commentId);
          if (isReply) {
            return c.copyWith(
              replies: c.replies.where((r) => r.id != commentId).toList(),
              repliesCount: c.repliesCount > 0 ? c.repliesCount - 1 : 0,
            );
          }
          return c;
        })
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
