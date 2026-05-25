import 'package:flutter_test/flutter_test.dart';
import 'package:novex_clean_arch/features/onboarding/presentation/state/onboarding_state.dart';

void main() {
  const base = OnboardingState(
    displayName: 'Ahmed Khan',
    username: 'ahmed_k92',
    city: 'Mardan, Khyber Pakhtunkhwa',
    usernameStatus: UsernameStatus.available,
  );

  test('hasResolvedLocation tracks whether coordinates are present', () {
    expect(base.hasResolvedLocation, isFalse);
    expect(base.copyWith(lat: 34.198, lng: 72.045).hasResolvedLocation, isTrue);
  });

  test('can continue with a typed city even before coordinates resolve', () {
    // Coordinates are resolved on Continue (forward-geocode), so the button is
    // enabled on typed text alone.
    expect(base.canContinueProfile, isTrue);
  });

  test('cannot continue with an empty city', () {
    expect(base.copyWith(city: '   ').canContinueProfile, isFalse);
  });

  test('cannot continue until the username is available', () {
    expect(
      base.copyWith(usernameStatus: UsernameStatus.checking).canContinueProfile,
      isFalse,
    );
  });
}
