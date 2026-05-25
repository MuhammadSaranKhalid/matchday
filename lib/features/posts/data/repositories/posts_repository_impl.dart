import 'package:fpdart/fpdart.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/post.dart';
import '../../domain/entities/post_draft.dart';
import '../../domain/repositories/posts_repository.dart';
import '../datasources/posts_remote_datasource.dart';

/// Online-only posts repository. The only place the remote data source's raw
/// exceptions become [Failure]s.
class PostsRepositoryImpl implements PostsRepository {
  PostsRepositoryImpl(this._remote, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final PostsRemoteDataSource _remote;
  final Uuid _uuid;

  @override
  Future<Either<Failure, List<Post>>> getFeed({
    int limit = 20,
    DateTime? before,
  }) async {
    try {
      final dtos = await _remote.getFeed(limit: limit, before: before);
      return Right(dtos.map((d) => d.toEntity()).toList());
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Post>>> getAuthorPosts(
    String authorId, {
    int limit = 20,
    DateTime? before,
  }) async {
    try {
      final dtos =
          await _remote.getByAuthor(authorId, limit: limit, before: before);
      return Right(dtos.map((d) => d.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Post>> createPost(PostDraft draft) async {
    try {
      // Deterministic post id → deterministic media paths → predictable public
      // URLs, so we can write media_urls/media at INSERT and upload after.
      final postId = _uuid.v4();
      final urls = <String>[];
      final media = <Map<String, dynamic>>[];
      for (var i = 0; i < draft.photos.length; i++) {
        final p = draft.photos[i];
        final url = _remote.publicUrl('$postId/$i.jpg');
        urls.add(url);
        media.add({
          'url': url,
          'blurhash': p.blurhash,
          'width': p.width,
          'height': p.height,
        });
      }

      final type = draft.hasPhotos ? PostType.photo : PostType.text;
      final dto = await _remote.insertPost({
        'post_id': postId,
        'author_context': draft.authorContext.wire,
        if (draft.contextEntityId != null)
          'context_entity_id': draft.contextEntityId,
        'post_type': type.wire,
        if (draft.text != null) 'text': draft.text,
        'media_urls': urls,
        'media': media,
        'visibility': 'public',
        'status': 'active',
      });

      if (draft.photos.isNotEmpty) {
        try {
          await _remote.uploadMedia(
            postId,
            draft.photos.map((p) => p.file).toList(),
          );
        } catch (_) {
          // Roll back the orphaned row (best-effort) so the feed never shows a
          // post whose images failed to upload, then surface the failure.
          try {
            await _remote.deletePost(postId);
          } catch (_) {}
          rethrow;
        }
      }
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
  Future<Either<Failure, Unit>> deletePost(PostId id) async {
    try {
      await _remote.deletePost(id.value);
      return const Right(unit);
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
