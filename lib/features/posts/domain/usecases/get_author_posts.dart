import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/post.dart';
import '../repositories/posts_repository.dart';

class GetAuthorPosts implements UseCase<List<Post>, GetAuthorPostsParams> {
  const GetAuthorPosts(this._repo);
  final PostsRepository _repo;

  @override
  Future<Either<Failure, List<Post>>> call(GetAuthorPostsParams p) =>
      _repo.getAuthorPosts(p.authorId, limit: p.limit, before: p.before);
}

class GetAuthorPostsParams {
  const GetAuthorPostsParams(this.authorId, {this.limit = 20, this.before});
  final String authorId;
  final int limit;
  final DateTime? before;
}
