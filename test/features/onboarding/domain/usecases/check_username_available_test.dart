import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:novex_clean_arch/core/error/failures.dart';
import 'package:novex_clean_arch/features/onboarding/domain/repositories/profile_repository.dart';
import 'package:novex_clean_arch/features/onboarding/domain/usecases/check_username_available.dart';

class _MockProfileRepo extends Mock implements ProfileRepository {}

void main() {
  late _MockProfileRepo repo;
  late CheckUsernameAvailable useCase;

  setUp(() {
    repo = _MockProfileRepo();
    useCase = CheckUsernameAvailable(repo);
  });

  test('short-circuits invalid formats without hitting the repo', () async {
    final result = await useCase('99');
    expect(result.getLeft().toNullable(), isA<ValidationFailure>());
    verifyNever(() => repo.isUsernameAvailable(any()));
  });

  test('delegates a valid username to the repo (available)', () async {
    when(() => repo.isUsernameAvailable('ahmed_k92'))
        .thenAnswer((_) async => const Right(true));
    final result = await useCase('ahmed_k92');
    expect(result.getRight().toNullable(), isTrue);
    verify(() => repo.isUsernameAvailable('ahmed_k92')).called(1);
  });

  test('passes through the repo verdict (taken)', () async {
    when(() => repo.isUsernameAvailable('ahmed_k92'))
        .thenAnswer((_) async => const Right(false));
    final result = await useCase('ahmed_k92');
    expect(result.getRight().toNullable(), isFalse);
  });
}
