import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:novex_clean_arch/core/error/failures.dart';
import 'package:novex_clean_arch/features/auth/domain/repositories/auth_repository.dart';
import 'package:novex_clean_arch/features/auth/domain/value_objects/email.dart';
import 'package:novex_clean_arch/features/auth/domain/value_objects/otp_code.dart';
import 'package:novex_clean_arch/features/auth/presentation/controllers/auth_controller.dart';
import 'package:novex_clean_arch/features/auth/presentation/providers/auth_providers.dart';
import 'package:novex_clean_arch/features/auth/presentation/state/auth_state.dart';

class _MockAuthRepo extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepo repo;

  setUpAll(() {
    registerFallbackValue(
      Email.create('a@b.co').getOrElse((_) => throw ''),
    );
    registerFallbackValue(
      OtpCode.create('123456').getOrElse((_) => throw ''),
    );
  });

  setUp(() {
    repo = _MockAuthRepo();
  });

  ProviderContainer makeContainer() => ProviderContainer.test(
        overrides: [
          authRepositoryProvider.overrideWithValue(repo),
        ],
      );

  test('sendOtp(valid email) → AuthOtpSent', () async {
    when(() => repo.sendEmailOtp(any()))
        .thenAnswer((_) async => const Right(unit));

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
    verifyNever(() =>
        repo.verifyEmailOtp(email: any(named: 'email'), code: any(named: 'code')));
  });
}
