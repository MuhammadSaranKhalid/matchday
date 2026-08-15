import 'package:fpdart/fpdart.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/comment.dart';
import '../../domain/repositories/comments_repository.dart';
import '../datasources/comments_remote_datasource.dart';

class CommentsRepositoryImpl implements CommentsRepository {
  CommentsRepositoryImpl(this._remote);

  final CommentsRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<Comment>>> getComments(String postId) async {
    try {
      final dtos = await _remote.getComments(postId);

      // Separate top-level comments and replies
      final topLevel = <Comment>[];
      final repliesByParent = <String, List<Comment>>{};

      for (final dto in dtos) {
        final comment = dto.toEntity();
        if (comment.parentCommentId == null) {
          topLevel.add(comment);
        } else {
          repliesByParent.putIfAbsent(comment.parentCommentId!, () => []).add(comment);
        }
      }

      // Attach replies to their parent top-level comments
      final tree = topLevel.map((parent) {
        final replies = repliesByParent[parent.id] ?? const [];
        return parent.copyWith(replies: replies);
      }).toList();

      return Right(tree);
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Comment>> addComment({
    required String postId,
    required String text,
    String? parentCommentId,
    List<String> mentionedUserIds = const [],
  }) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) {
      return const Left(ValidationFailure('Comment cannot be empty'));
    }
    if (cleanText.length > 500) {
      return const Left(ValidationFailure('Comment is too long (max 500 characters)'));
    }

    try {
      final dto = await _remote.insertComment(
        postId: postId,
        text: cleanText,
        parentCommentId: parentCommentId,
        mentionedUserIds: mentionedUserIds,
      );
      return Right(dto.toEntity());
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteComment(String commentId) async {
    try {
      await _remote.deleteComment(commentId);
      return const Right(unit);
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> toggleCommentLike(String commentId) async {
    try {
      final isLiked = await _remote.toggleCommentLike(commentId);
      return Right(isLiked);
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
