import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/comment.dart';
import '../../domain/entities/comment_like_result.dart';
import '../../domain/repositories/comments_repository.dart';
import '../datasources/comments_remote_datasource.dart';

class CommentsRepositoryImpl implements CommentsRepository {
  CommentsRepositoryImpl(this._remote);

  final CommentsRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<Comment>>> getComments(
    String postId, {
    DateTime? cursorCreatedAt,
    String? cursorCommentId,
    int limit = 20,
  }) async {
    try {
      final dtos = await _remote.getComments(
        postId,
        cursorCreatedAt: cursorCreatedAt,
        cursorCommentId: cursorCommentId,
        limit: limit,
      );
      return Right(dtos.map((dto) => dto.toEntity()).toList());
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on PostgrestException catch (e) {
      return Left(ServerFailure(e.message));
    } on SocketException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Comment>>> getCommentReplies(
    String parentCommentId, {
    DateTime? cursorCreatedAt,
    String? cursorCommentId,
    int limit = 20,
  }) async {
    try {
      final dtos = await _remote.getCommentReplies(
        parentCommentId,
        cursorCreatedAt: cursorCreatedAt,
        cursorCommentId: cursorCommentId,
        limit: limit,
      );
      return Right(dtos.map((dto) => dto.toEntity()).toList());
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on PostgrestException catch (e) {
      return Left(ServerFailure(e.message));
    } on SocketException catch (e) {
      return Left(NetworkFailure(e.message));
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
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on PostgrestException catch (e) {
      return Left(ServerFailure(e.message));
    } on SocketException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteComment(String commentId) async {
    try {
      await _remote.deleteComment(commentId);
      return const Right(unit);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on PostgrestException catch (e) {
      return Left(ServerFailure(e.message));
    } on SocketException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CommentLikeResult>> setCommentLike(
    String commentId, {
    required bool liked,
  }) async {
    try {
      final result = await _remote.setCommentLike(commentId, liked: liked);
      return Right(result);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on PostgrestException catch (e) {
      return Left(ServerFailure(e.message));
    } on SocketException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
