import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';
import '../value_objects/email.dart';

class SendEmailOtp implements UseCase<Unit, Email> {
  const SendEmailOtp(this._repo);
  final AuthRepository _repo;

  @override
  Future<Either<Failure, Unit>> call(Email email) => _repo.sendEmailOtp(email);
}
