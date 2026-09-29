import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/pending_post.dart';
import '../entities/post.dart';
import '../entities/post_draft.dart';
import '../entities/post_like_result.dart';
import '../entities/publish_photo.dart';
import '../value_objects/post_text.dart';

/// CQRS Command/Write Model Repository for Posts.
/// Enforces authorization, validation, transactional outbox reservation, and state mutations.
abstract class PostCommandRepository {
  /// Asynchronously begins publishing a post:
  /// Persists an idempotent command, creates the NestJS-owned draft, uploads
  /// directly with signed Storage tokens, then issues one publish command.
  Future<Either<Failure, String>> beginPublishPost({
    required PostPublisherType publisherType,
    required String publisherId,
    required PostKind postKind,
    required PostText text,
    required List<PublishPhoto> photos,
    String? linkedMatchId,
    String? linkedTournamentId,
    String? linkedTeamId,
  });

  /// Soft-delete a post the current user/entity authored.
  Future<Either<Failure, Unit>> deletePost(PostId id);

  /// Desired-state like: sets liked to true or false deterministically.
  Future<Either<Failure, PostLikeResult>> setPostLike(
    PostId id, {
    required bool liked,
  });

  /// Desired-state bookmark: sets bookmarked to true or false deterministically.
  Future<Either<Failure, bool>> setPostBookmark(
    PostId id, {
    required bool bookmarked,
  });

  /// Realtime stream of creator's locally queued and active publishing posts (outbox).
  Stream<List<PendingPost>> watchPendingPosts();

  /// Retry an upload/publishing session for a failed pending post.
  Future<void> retryPendingPost(String postId);

  /// Discard a failed pending post and clean up local temporary files.
  Future<void> discardPendingPost(String postId);

  /// Acknowledges that a post is confirmed published and active,
  /// cleaning up local outbox records and cached temporary files
  /// without triggering server-side abandon commands.
  Future<void> acknowledgePublishedLocally(String postId);

  /// Scans local outbox on startup, resumes in-flight staging uploads,
  /// and reconciles already-published posts with server state.
  Future<void> recoverPendingPosts();

  /// Composer submit helper that wraps beginPublishPost.
  Future<Either<Failure, Post>> createPost(PostDraft draft);
}
