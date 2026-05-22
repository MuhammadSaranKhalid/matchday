import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:novex_clean_arch/core/error/failures.dart';
import 'package:novex_clean_arch/features/onboarding/domain/entities/player_profile.dart';
import 'package:novex_clean_arch/features/onboarding/domain/entities/profile.dart';
import 'package:novex_clean_arch/features/onboarding/domain/repositories/profile_repository.dart';
import 'package:novex_clean_arch/features/onboarding/domain/usecases/complete_onboarding.dart';
import 'package:novex_clean_arch/features/onboarding/domain/value_objects/city.dart';
import 'package:novex_clean_arch/features/onboarding/domain/value_objects/display_name.dart';
import 'package:novex_clean_arch/features/onboarding/domain/value_objects/username.dart';

class _MockProfileRepo extends Mock implements ProfileRepository {}

void main() {
  late _MockProfileRepo repo;
  late CompleteOnboarding useCase;

  const profile = Profile(userId: ProfileUserId('u1'), username: 'ahmed_k92');

  setUpAll(() {
    registerFallbackValue(DisplayName.create('Ahmed Khan').getRight().toNullable()!);
    registerFallbackValue(Username.create('ahmed_k92').getRight().toNullable()!);
    registerFallbackValue(City.create('Lahore').getRight().toNullable()!);
    registerFallbackValue(const PlayerProfile());
  });

  setUp(() {
    repo = _MockProfileRepo();
    useCase = CompleteOnboarding(repo);
    when(() => repo.completeOnboarding(
          displayName: any(named: 'displayName'),
          username: any(named: 'username'),
          city: any(named: 'city'),
          playerProfile: any(named: 'playerProfile'),
        )).thenAnswer((_) async => const Right(profile));
  });

  CompleteOnboardingParams params({
    String displayName = 'Ahmed Khan',
    String username = 'ahmed_k92',
    String city = 'Lahore, Punjab',
    PlayerProfile? player,
  }) =>
      CompleteOnboardingParams(
        displayName: displayName,
        username: username,
        city: city,
        playerProfile: player,
      );

  test('rejects an invalid display name without calling the repo', () async {
    final result = await useCase(params(displayName: ' '));
    expect(result.getLeft().toNullable(), isA<ValidationFailure>());
    verifyNever(() => repo.completeOnboarding(
          displayName: any(named: 'displayName'),
          username: any(named: 'username'),
          city: any(named: 'city'),
          playerProfile: any(named: 'playerProfile'),
        ));
  });

  test('rejects an invalid username', () async {
    final result = await useCase(params(username: '99'));
    expect(result.getLeft().toNullable(), isA<ValidationFailure>());
  });

  test('rejects an empty city', () async {
    final result = await useCase(params(city: '   '));
    expect(
      result.getLeft().toNullable(),
      isA<ValidationFailure>()
          .having((f) => f.message, 'message', 'City is required'),
    );
  });

  test('forwards a non-player profile as null player_profile', () async {
    final result = await useCase(params());
    expect(result.isRight(), isTrue);
    verify(() => repo.completeOnboarding(
          displayName: any(named: 'displayName'),
          username: any(named: 'username'),
          city: any(named: 'city'),
          playerProfile: null,
        )).called(1);
  });

  test('drops an empty player profile to null', () async {
    await useCase(params(player: const PlayerProfile()));
    verify(() => repo.completeOnboarding(
          displayName: any(named: 'displayName'),
          username: any(named: 'username'),
          city: any(named: 'city'),
          playerProfile: null,
        )).called(1);
  });

  test('forwards a populated player profile', () async {
    const player = PlayerProfile(role: PlayerRole.allRounder);
    await useCase(params(player: player));
    verify(() => repo.completeOnboarding(
          displayName: any(named: 'displayName'),
          username: any(named: 'username'),
          city: any(named: 'city'),
          playerProfile: player,
        )).called(1);
  });
}
