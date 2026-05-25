import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/post.dart';
import '../entities/post_draft.dart';
import '../repositories/posts_repository.dart';

/// Business rules for creating a post live here, not in the controller/repo:
/// content required (text OR ≥1 photo), text ≤ 2000 chars, ≤ 4 photos.
class CreatePost implements UseCase<Post, PostDraft> {
  const CreatePost(this._repo);
  final PostsRepository _repo;

  static const maxChars = 2000;
  static const maxPhotos = 4;

  @override
  Future<Either<Failure, Post>> call(PostDraft draft) async {
    final text = draft.text?.trim();
    final hasText = text != null && text.isNotEmpty;

    if (!hasText && !draft.hasPhotos) {
      return const Left(
        ValidationFailure('Add some text or a photo to post.'),
      );
    }
    if (text != null && text.length > maxChars) {
      return const Left(
        ValidationFailure('Post is too long (max $maxChars characters).'),
      );
    }
    if (draft.photos.length > maxPhotos) {
      return const Left(
        ValidationFailure('A post can have at most $maxPhotos photos.'),
      );
    }

    // Hand the repo a normalised draft (trimmed text, null when empty).
    return _repo.createPost(
      PostDraft(
        text: hasText ? text : null,
        photos: draft.photos,
        authorContext: draft.authorContext,
        contextEntityId: draft.contextEntityId,
      ),
    );
  }
}
