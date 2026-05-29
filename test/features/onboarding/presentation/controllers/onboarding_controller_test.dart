import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:novex_clean_arch/core/database/database_provider.dart';
import 'package:novex_clean_arch/core/database/wizard_draft_store.dart';
import 'package:novex_clean_arch/features/onboarding/domain/entities/profile.dart';
import 'package:novex_clean_arch/features/onboarding/domain/repositories/profile_repository.dart';
import 'package:novex_clean_arch/features/onboarding/domain/value_objects/city.dart';
import 'package:novex_clean_arch/features/onboarding/domain/value_objects/display_name.dart';
import 'package:novex_clean_arch/features/onboarding/domain/value_objects/username.dart';
import 'package:novex_clean_arch/features/onboarding/presentation/controllers/onboarding_controller.dart';
import 'package:novex_clean_arch/features/onboarding/presentation/providers/onboarding_providers.dart';
import 'package:novex_clean_arch/features/onboarding/presentation/state/onboarding_state.dart';

class _MockProfileRepo extends Mock implements ProfileRepository {}

class _MockDraftStore extends Mock implements WizardDraftStore {}

void main() {
  late _MockProfileRepo repo;
  late _MockDraftStore store;

  setUpAll(() {
    registerFallbackValue(
      DisplayName.create('Test User').getOrElse((_) => throw ''),
    );
    registerFallbackValue(
      Username.create('test_user').getOrElse((_) => throw ''),
    );
    registerFallbackValue(
      City.create('Lahore').getOrElse((_) => throw ''),
    );
  });

  setUp(() {
    repo = _MockProfileRepo();
    store = _MockDraftStore();
    when(() => store.load(any())).thenAnswer((_) async => null);
    when(() => store.save(any(), any())).thenAnswer((_) async {});
    when(() => store.clear(any())).thenAnswer((_) async {});
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer.test(
      overrides: [
        profileRepositoryProvider.overrideWithValue(repo),
        wizardDraftStoreProvider.overrideWithValue(store),
      ],
    );
    addTearDown(container.dispose);
    // Hold a live subscription so the autodispose controller (and its pending
    // username-debounce timer) survives across awaits in the test.
    container.listen(onboardingControllerProvider, (_, __) {});
    return container;
  }

  test('build with no draft yields the default profile step', () async {
    final container = makeContainer();
    final state = await container.read(onboardingControllerProvider.future);
    expect(state.step, OnboardingStep.profile);
    expect(state.username, isEmpty);
    expect(state.usernameStatus, UsernameStatus.idle);
  });

  test('a valid username goes checking → available after the debounce',
      () async {
    when(() => repo.isUsernameAvailable('ahmed_k92'))
        .thenAnswer((_) async => const Right(true));

    final container = makeContainer();
    await container.read(onboardingControllerProvider.future);
    final controller = container.read(onboardingControllerProvider.notifier);

    controller.setUsername('ahmed_k92');
    expect(
      container.read(onboardingControllerProvider).value!.usernameStatus,
      UsernameStatus.checking,
    );

    await Future<void>.delayed(const Duration(milliseconds: 600));

    expect(
      container.read(onboardingControllerProvider).value!.usernameStatus,
      UsernameStatus.available,
    );
    verify(() => repo.isUsernameAvailable('ahmed_k92')).called(1);
  });

  test('an invalid username is rejected synchronously, no network check',
      () async {
    final container = makeContainer();
    await container.read(onboardingControllerProvider.future);
    final controller = container.read(onboardingControllerProvider.notifier);

    controller.setUsername('99'); // leading digit
    expect(
      container.read(onboardingControllerProvider).value!.usernameStatus,
      UsernameStatus.invalid,
    );

    await Future<void>.delayed(const Duration(milliseconds: 600));
    verifyNever(() => repo.isUsernameAvailable(any()));
  });

  test('submit success advances to the welcome step', () async {
    when(() => repo.completeOnboarding(
          displayName: any(named: 'displayName'),
          username: any(named: 'username'),
          city: any(named: 'city'),
          placeId: any(named: 'placeId'),
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          countryCode: any(named: 'countryCode'),
          playerProfile: any(named: 'playerProfile'),
        )).thenAnswer(
      (_) async => const Right(
        Profile(userId: ProfileUserId('u1'), username: 'ahmed_k92'),
      ),
    );

    final container = makeContainer();
    await container.read(onboardingControllerProvider.future);
    final controller = container.read(onboardingControllerProvider.notifier);

    controller.setDisplayName('Ahmed Khan');
    controller.setUsername('ahmed_k92');
    controller.setCity('Lahore, Punjab');

    await controller.submit(asPlayer: false);

    final state = container.read(onboardingControllerProvider).value!;
    expect(state.step, OnboardingStep.welcome);
    expect(state.submitting, isFalse);
    expect(state.submitError, isNull);
    verify(() => repo.completeOnboarding(
          displayName: any(named: 'displayName'),
          username: any(named: 'username'),
          city: any(named: 'city'),
          placeId: any(named: 'placeId'),
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          countryCode: any(named: 'countryCode'),
          playerProfile: any(named: 'playerProfile'),
        )).called(1);
  });
}
