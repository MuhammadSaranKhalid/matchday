import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/pending_post.dart';
import '../entities/post.dart';
import '../entities/post_draft.dart';
import '../entities/post_like_result.dart';
import '../entities/publish_photo.dart';
import '../value_objects/post_text.dart';

import 'post_command_repository.dart';
import 'post_read_repository.dart';

/// Authoritative Posts repository combining CQRS read and command capabilities.
abstract class PostsRepository implements PostReadRepository, PostCommandRepository {
  /// Consolidated feed read projection supporting legacy 'mode' parameter.
  @override
  Future<Either<Failure, List<Post>>> getHomeFeed({
    String mode = 'home',
    String filter = 'all',
    String? targetId,
    DateTime? cursorPublishedAt,
    String? cursorPostId,
    int limit = 20,
  });

  @override
  Future<Either<Failure, Post>> getPost(PostId id);

  @override
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

  @override
  Future<Either<Failure, Unit>> deletePost(PostId id);

  @override
  Future<Either<Failure, PostLikeResult>> setPostLike(PostId id, {required bool liked});

  @override
  Future<Either<Failure, bool>> setPostBookmark(PostId id, {required bool bookmarked});

  @override
  Stream<List<PendingPost>> watchPendingPosts();

  @override
  Future<void> retryPendingPost(String postId);

  @override
  Future<void> discardPendingPost(String postId);

  @override
  Future<Either<Failure, Post>> createPost(PostDraft draft);
}
