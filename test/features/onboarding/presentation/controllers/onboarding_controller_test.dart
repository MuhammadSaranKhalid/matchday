import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:matchday/core/database/database_provider.dart';
import 'package:matchday/core/database/wizard_draft_store.dart';
import 'package:matchday/features/onboarding/domain/entities/profile.dart';
import 'package:matchday/features/onboarding/domain/repositories/profile_repository.dart';
import 'package:matchday/features/onboarding/domain/value_objects/city.dart';
import 'package:matchday/features/onboarding/domain/value_objects/display_name.dart';
import 'package:matchday/features/onboarding/domain/value_objects/username.dart';
import 'package:matchday/features/onboarding/presentation/controllers/onboarding_controller.dart';
import 'package:matchday/features/onboarding/presentation/providers/onboarding_providers.dart';
import 'package:matchday/features/onboarding/presentation/state/onboarding_state.dart';
import 'package:matchday/features/location/domain/entities/geo_place.dart';
import 'package:matchday/features/location/domain/repositories/location_repository.dart';
import 'package:matchday/features/location/presentation/providers/location_providers.dart';

class _MockProfileRepo extends Mock implements ProfileRepository {}

class _MockDraftStore extends Mock implements WizardDraftStore {}

class _MockLocationRepo extends Mock implements LocationRepository {}

void main() {
  late _MockProfileRepo repo;
  late _MockDraftStore store;
  late _MockLocationRepo locationRepo;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
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
    locationRepo = _MockLocationRepo();
    when(() => store.load(any())).thenAnswer((_) async => null);
    when(() => store.save(any(), any())).thenAnswer((_) async {});
    when(() => store.clear(any())).thenAnswer((_) async {});
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer.test(
      overrides: [
        profileRepositoryProvider.overrideWithValue(repo),
        wizardDraftStoreProvider.overrideWithValue(store),
        locationRepositoryProvider.overrideWithValue(locationRepo),
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
    expect(state.profile.username, isEmpty);
    expect(state.profile.usernameStatus, UsernameStatus.idle);
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
      container.read(onboardingControllerProvider).value!.profile.usernameStatus,
      UsernameStatus.checking,
    );

    await Future<void>.delayed(const Duration(milliseconds: 600));

    expect(
      container.read(onboardingControllerProvider).value!.profile.usernameStatus,
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
      container.read(onboardingControllerProvider).value!.profile.usernameStatus,
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

  test('useMyLocation stores the locality in city, not the full address',
      () async {
    when(() => locationRepo.currentLocation(
          languageCode: any(named: 'languageCode'),
        )).thenAnswer(
      (_) async => const Right(
        GeoPlace(
          label:
              '12-A Street 1, Block-E-II, Gulberg III, Lahore, 54000, Pakistan',
          source: PlaceSource.gps,
          city: 'Lahore',
          district: 'Lahore',
          province: 'Punjab',
          postcode: '54000',
          latitude: 31.5204,
          longitude: 74.3587,
          countryCode: 'PK',
        ),
      ),
    );

    final container = makeContainer();
    await container.read(onboardingControllerProvider.future);
    final controller = container.read(onboardingControllerProvider.notifier);

    await controller.useMyLocation();

    final p = container.read(onboardingControllerProvider).value!.profile;
    expect(p.city, 'Lahore',
        reason: 'city must be the locality, not the formatted address');
    expect(p.label, contains('Gulberg III'));
    expect(p.district, 'Lahore');
    expect(p.province, 'Punjab');
    expect(p.postcode, '54000');
    expect(p.lat, 31.5204);
    expect(p.countryCode, 'PK');
  });
}
