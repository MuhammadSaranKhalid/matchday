import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

class SignOut implements UseCase<Unit, NoParams> {
  const SignOut(this._repo);
  final AuthRepository _repo;

  @override
  Future<Either<Failure, Unit>> call(NoParams _) => _repo.signOut();
}
