import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/post.dart';
import '../repositories/posts_repository.dart';

class DeletePost implements UseCase<Unit, PostId> {
  const DeletePost(this._repo);
  final PostsRepository _repo;

  @override
  Future<Either<Failure, Unit>> call(PostId id) => _repo.deletePost(id);
}
