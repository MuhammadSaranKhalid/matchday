import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:novex_clean_arch/core/error/failures.dart';
import 'package:novex_clean_arch/features/auth/domain/usecases/send_email_otp.dart';
import 'package:novex_clean_arch/features/auth/domain/usecases/verify_email_otp.dart';
import 'package:novex_clean_arch/features/auth/domain/value_objects/email.dart';
import 'package:novex_clean_arch/features/auth/domain/value_objects/otp_code.dart';
import 'package:novex_clean_arch/features/auth/presentation/controllers/auth_controller.dart';
import 'package:novex_clean_arch/features/auth/presentation/providers/auth_providers.dart';
import 'package:novex_clean_arch/features/auth/presentation/state/auth_state.dart';

class _MockSendOtp extends Mock implements SendEmailOtp {}

class _MockVerifyOtp extends Mock implements VerifyEmailOtp {}

void main() {
  late _MockSendOtp sendOtp;
  late _MockVerifyOtp verifyOtp;

  setUpAll(() {
    registerFallbackValue(
      Email.create('a@b.co').getOrElse((_) => throw ''),
    );
    registerFallbackValue(
      VerifyEmailOtpParams(
        email: Email.create('a@b.co').getOrElse((_) => throw ''),
        code: OtpCode.create('123456').getOrElse((_) => throw ''),
      ),
    );
  });

  setUp(() {
    sendOtp = _MockSendOtp();
    verifyOtp = _MockVerifyOtp();
  });

  ProviderContainer makeContainer() => ProviderContainer.test(
        overrides: [
          sendEmailOtpUseCaseProvider.overrideWithValue(sendOtp),
          verifyEmailOtpUseCaseProvider.overrideWithValue(verifyOtp),
        ],
      );

  test('sendOtp(valid email) → AuthOtpSent', () async {
    when(() => sendOtp(any())).thenAnswer((_) async => const Right(unit));

    final c = makeContainer();
    addTearDown(c.dispose);

    await c.read(authControllerProvider.notifier).sendOtp('h@novex.studio');

    expect(c.read(authControllerProvider), isA<AuthOtpSent>());
    verify(() => sendOtp(any())).called(1);
  });

  test('sendOtp(invalid email) → AuthFailed without calling repo', () async {
    final c = makeContainer();
    addTearDown(c.dispose);

    await c.read(authControllerProvider.notifier).sendOtp('not-an-email');

    final state = c.read(authControllerProvider);
    expect(state, isA<AuthFailed>());
    expect((state as AuthFailed).failure, isA<ValidationFailure>());
    verifyNever(() => sendOtp(any()));
  });

  test('verifyOtp without prior sendOtp → AuthFailed', () async {
    final c = makeContainer();
    addTearDown(c.dispose);

    await c.read(authControllerProvider.notifier).verifyOtp('123456');

    final state = c.read(authControllerProvider);
    expect(state, isA<AuthFailed>());
    expect((state as AuthFailed).failure, isA<ValidationFailure>());
    verifyNever(() => verifyOtp(any()));
  });
}
