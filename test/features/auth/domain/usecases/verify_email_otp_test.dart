import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:novex_clean_arch/core/error/failures.dart';
import 'package:novex_clean_arch/features/auth/domain/entities/user.dart';
import 'package:novex_clean_arch/features/auth/domain/repositories/auth_repository.dart';
import 'package:novex_clean_arch/features/auth/domain/usecases/verify_email_otp.dart';
import 'package:novex_clean_arch/features/auth/domain/value_objects/email.dart';
import 'package:novex_clean_arch/features/auth/domain/value_objects/otp_code.dart';

class _MockAuthRepo extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepo repo;
  late VerifyEmailOtp useCase;

  setUpAll(() {
    registerFallbackValue(
      Email.create('a@b.co').getOrElse((_) => throw 'unreachable'),
    );
    registerFallbackValue(
      OtpCode.create('123456').getOrElse((_) => throw 'unreachable'),
    );
  });

  setUp(() {
    repo = _MockAuthRepo();
    useCase = VerifyEmailOtp(repo);
  });

  test('returns the User when the repo accepts the code', () async {
    final email = Email.create('h@novex.studio').getOrElse((_) => throw '');
    final code = OtpCode.create('123456').getOrElse((_) => throw '');
    final user = User(
      id: const UserId('u1'),
      email: email,
      displayName: 'Hassaan',
    );

    when(
      () => repo.verifyEmailOtp(
        email: any(named: 'email'),
        code: any(named: 'code'),
      ),
    ).thenAnswer((_) async => Right(user));

    final result =
        await useCase(VerifyEmailOtpParams(email: email, code: code));

    expect(result, equals(Right<Failure, User>(user)));
    verify(() => repo.verifyEmailOtp(email: email, code: code)).called(1);
  });

  test('propagates AuthFailure on a bad code', () async {
    final email = Email.create('h@novex.studio').getOrElse((_) => throw '');
    final code = OtpCode.create('000000').getOrElse((_) => throw '');

    when(
      () => repo.verifyEmailOtp(
        email: any(named: 'email'),
        code: any(named: 'code'),
      ),
    ).thenAnswer(
      (_) async => const Left(AuthFailure('Token has expired or is invalid')),
    );

    final result =
        await useCase(VerifyEmailOtpParams(email: email, code: code));

    expect(result.isLeft(), isTrue);
    expect(result.getLeft().toNullable(), isA<AuthFailure>());
  });
}
