import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/post.dart';
import '../repositories/posts_repository.dart';

class GetFeed implements UseCase<List<Post>, GetFeedParams> {
  const GetFeed(this._repo);
  final PostsRepository _repo;

  @override
  Future<Either<Failure, List<Post>>> call(GetFeedParams p) =>
      _repo.getFeed(limit: p.limit, before: p.before);
}

class GetFeedParams {
  const GetFeedParams({this.limit = 20, this.before});
  final int limit;
  final DateTime? before;
}
