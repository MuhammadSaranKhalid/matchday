import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class SignInWithGoogle implements UseCase<User, NoParams> {
  const SignInWithGoogle(this._repo);
  final AuthRepository _repo;

  @override
  Future<Either<Failure, User>> call(NoParams _) => _repo.signInWithGoogle();
}
