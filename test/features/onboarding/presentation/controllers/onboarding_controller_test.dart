import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:novex_clean_arch/core/database/database_provider.dart';
import 'package:novex_clean_arch/core/database/wizard_draft_store.dart';
import 'package:novex_clean_arch/features/onboarding/domain/entities/profile.dart';
import 'package:novex_clean_arch/features/onboarding/domain/usecases/check_username_available.dart';
import 'package:novex_clean_arch/features/onboarding/domain/usecases/complete_onboarding.dart';
import 'package:novex_clean_arch/features/onboarding/presentation/controllers/onboarding_controller.dart';
import 'package:novex_clean_arch/features/onboarding/presentation/providers/onboarding_providers.dart';
import 'package:novex_clean_arch/features/onboarding/presentation/state/onboarding_state.dart';

class _MockCheck extends Mock implements CheckUsernameAvailable {}

class _MockComplete extends Mock implements CompleteOnboarding {}

class _MockDraftStore extends Mock implements WizardDraftStore {}

void main() {
  late _MockCheck check;
  late _MockComplete complete;
  late _MockDraftStore store;

  setUpAll(() {
    registerFallbackValue(
      const CompleteOnboardingParams(
        displayName: 'x',
        username: 'xxx',
        city: 'x',
      ),
    );
  });

  setUp(() {
    check = _MockCheck();
    complete = _MockComplete();
    store = _MockDraftStore();
    when(() => store.load(any())).thenAnswer((_) async => null);
    when(() => store.save(any(), any())).thenAnswer((_) async {});
    when(() => store.clear(any())).thenAnswer((_) async {});
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer.test(
      overrides: [
        checkUsernameAvailableUseCaseProvider.overrideWithValue(check),
        completeOnboardingUseCaseProvider.overrideWithValue(complete),
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
    when(() => check.call('ahmed_k92'))
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
    verify(() => check.call('ahmed_k92')).called(1);
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
    verifyNever(() => check.call(any()));
  });

  test('submit success advances to the welcome step', () async {
    when(() => complete.call(any())).thenAnswer(
      (_) async => const Right(
        Profile(userId: ProfileUserId('u1'), username: 'ahmed_k92'),
      ),
    );

    final container = makeContainer();
    await container.read(onboardingControllerProvider.future);
    final controller = container.read(onboardingControllerProvider.notifier);

    controller.setDisplayName('Ahmed Khan');
    controller.setCity('Lahore, Punjab');

    await controller.submit(asPlayer: false);

    final state = container.read(onboardingControllerProvider).value!;
    expect(state.step, OnboardingStep.welcome);
    expect(state.submitting, isFalse);
    expect(state.submitError, isNull);
    verify(() => complete.call(any())).called(1);
  });
}
