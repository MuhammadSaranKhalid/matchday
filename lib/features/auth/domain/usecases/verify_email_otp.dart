import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';
import '../value_objects/email.dart';
import '../value_objects/otp_code.dart';

class VerifyEmailOtp implements UseCase<User, VerifyEmailOtpParams> {
  const VerifyEmailOtp(this._repo);
  final AuthRepository _repo;

  @override
  Future<Either<Failure, User>> call(VerifyEmailOtpParams p) =>
      _repo.verifyEmailOtp(email: p.email, code: p.code);
}

class VerifyEmailOtpParams {
  const VerifyEmailOtpParams({required this.email, required this.code});
  final Email email;
  final OtpCode code;
}
