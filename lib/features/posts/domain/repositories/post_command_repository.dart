import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/pending_post.dart';
import '../entities/post.dart';
import '../entities/post_draft.dart';
import '../entities/publish_photo.dart';
import '../value_objects/post_text.dart';

/// CQRS Command/Write Model Repository for Posts.
/// Enforces authorization, validation, transactional outbox reservation, and state mutations.
abstract class PostCommandRepository {
  /// Asynchronously begins publishing a post:
  /// Normalizes local photos, reserves the publishing session on the server via begin_post_publish,
  /// starts uploading to private staging storage, and emits a durable PendingPost.
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
  Future<Either<Failure, bool>> setPostLike(PostId id, {required bool liked});

  /// Desired-state bookmark: sets bookmarked to true or false deterministically.
  Future<Either<Failure, bool>> setPostBookmark(PostId id, {required bool bookmarked});

  /// Realtime stream of creator's locally queued and active publishing posts (outbox).
  Stream<List<PendingPost>> watchPendingPosts();

  /// Retry an upload/publishing session for a failed pending post.
  Future<void> retryPendingPost(String postId);

  /// Discard a failed pending post and clean up local temporary files.
  Future<void> discardPendingPost(String postId);

  /// Composer submit helper that wraps beginPublishPost.
  Future<Either<Failure, Post>> createPost(PostDraft draft);
}
