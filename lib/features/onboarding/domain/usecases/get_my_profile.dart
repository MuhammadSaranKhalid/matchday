import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/profile.dart';
import '../repositories/profile_repository.dart';

/// Fetch the signed-in user's profile (or null). Drives the router's
/// onboarding gate.
class GetMyProfile implements UseCase<Profile?, NoParams> {
  const GetMyProfile(this._repo);
  final ProfileRepository _repo;

  @override
  Future<Either<Failure, Profile?>> call(NoParams params) =>
      _repo.getMyProfile();
}
