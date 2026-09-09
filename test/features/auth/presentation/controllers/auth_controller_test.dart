import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:matchday/core/error/failures.dart';
import 'package:matchday/features/auth/domain/repositories/auth_repository.dart';
import 'package:matchday/features/auth/domain/value_objects/email.dart';
import 'package:matchday/features/auth/domain/value_objects/otp_code.dart';
import 'package:matchday/features/auth/presentation/controllers/auth_controller.dart';
import 'package:matchday/features/auth/presentation/providers/auth_providers.dart';
import 'package:matchday/features/auth/presentation/state/auth_state.dart';

class _MockAuthRepo extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepo repo;

  setUpAll(() {
    registerFallbackValue(Email.create('a@b.co').getOrElse((_) => throw ''));
    registerFallbackValue(OtpCode.create('123456').getOrElse((_) => throw ''));
  });

  setUp(() {
    repo = _MockAuthRepo();
  });

  ProviderContainer makeContainer() => ProviderContainer.test(
    overrides: [authRepositoryProvider.overrideWithValue(repo)],
  );

  test('sendOtp(valid email) → AuthOtpSent', () async {
    when(
      () => repo.sendEmailOtp(any()),
    ).thenAnswer((_) async => const Right(unit));

    final c = makeContainer();
    addTearDown(c.dispose);

    await c.read(authControllerProvider.notifier).sendOtp('h@novex.studio');

    expect(c.read(authControllerProvider), isA<AuthOtpSent>());
    verify(() => repo.sendEmailOtp(any())).called(1);
  });

  test('sendOtp(invalid email) → AuthFailed without calling repo', () async {
    final c = makeContainer();
    addTearDown(c.dispose);

    await c.read(authControllerProvider.notifier).sendOtp('not-an-email');

    final state = c.read(authControllerProvider);
    expect(state, isA<AuthFailed>());
    expect((state as AuthFailed).failure, isA<ValidationFailure>());
    verifyNever(() => repo.sendEmailOtp(any()));
  });

  test('verifyOtp without prior sendOtp → AuthFailed', () async {
    final c = makeContainer();
    addTearDown(c.dispose);

    await c.read(authControllerProvider.notifier).verifyOtp('123456');

    final state = c.read(authControllerProvider);
    expect(state, isA<AuthFailed>());
    expect((state as AuthFailed).failure, isA<ValidationFailure>());
    verifyNever(
      () => repo.verifyEmailOtp(
        email: any(named: 'email'),
        code: any(named: 'code'),
      ),
    );
  });

  test('resendOtp keeps the user in the OTP flow', () async {
    when(
      () => repo.sendEmailOtp(any()),
    ).thenAnswer((_) async => const Right(unit));

    final c = makeContainer();
    addTearDown(c.dispose);

    await c.read(authControllerProvider.notifier).sendOtp('h@novex.studio');
    await c.read(authControllerProvider.notifier).resendOtp();

    final state = c.read(authControllerProvider);
    expect(state, isA<AuthOtpSent>());
    expect((state as AuthOtpSent).email.value, 'h@novex.studio');
    verify(() => repo.sendEmailOtp(any())).called(2);
  });

  test('verifyOtp failure keeps the user on the OTP form', () async {
    when(
      () => repo.sendEmailOtp(any()),
    ).thenAnswer((_) async => const Right(unit));
    when(
      () => repo.verifyEmailOtp(
        email: any(named: 'email'),
        code: any(named: 'code'),
      ),
    ).thenAnswer(
      (_) async => const Left(AuthFailure('That code is not correct')),
    );

    final c = makeContainer();
    addTearDown(c.dispose);

    await c.read(authControllerProvider.notifier).sendOtp('h@novex.studio');
    await c.read(authControllerProvider.notifier).verifyOtp('123456');

    final state = c.read(authControllerProvider);
    expect(state, isA<AuthFailed>());
    expect((state as AuthFailed).showOtpForm, isTrue);
  });
}
