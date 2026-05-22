import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/profile_repository.dart';
import '../value_objects/username.dart';

/// Validate a username's format, then check backend availability. Returns a
/// [ValidationFailure] (without hitting the network) when the format is wrong,
/// so the controller can show the right inline message.
class CheckUsernameAvailable implements UseCase<bool, String> {
  const CheckUsernameAvailable(this._repo);
  final ProfileRepository _repo;

  @override
  Future<Either<Failure, bool>> call(String raw) async {
    return Username.create(raw).fold(
      (failure) => Left(failure),
      (username) => _repo.isUsernameAvailable(username.value),
    );
  }
}
