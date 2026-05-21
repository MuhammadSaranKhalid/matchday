import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// One-shot read — used to bootstrap the app from cache on launch.
class GetCurrentUser implements UseCase<User?, NoParams> {
  const GetCurrentUser(this._repo);
  final AuthRepository _repo;

  @override
  Future<Either<Failure, User?>> call(NoParams _) => _repo.getCurrentUser();
}

/// Reactive stream — drives auth-aware routing & global UI.
class WatchCurrentUser implements StreamUseCase<User?, NoParams> {
  const WatchCurrentUser(this._repo);
  final AuthRepository _repo;

  @override
  Stream<User?> call(NoParams _) => _repo.watchCurrentUser();
}
