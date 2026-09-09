import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:matchday/features/onboarding/presentation/controllers/onboarding_controller.dart';
import 'package:matchday/core/supabase/supabase_client_provider.dart';
import 'package:matchday/features/profile/domain/entities/profile.dart';
import 'package:matchday/features/profile/domain/repositories/profile_repository.dart';
import 'package:matchday/features/profile/presentation/providers/profile_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockProfileRepository extends Mock implements ProfileRepository {}

class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _MockGoTrueClient extends Mock implements GoTrueClient {}

void main() {
  late _MockProfileRepository repository;
  late _MockSupabaseClient supabase;
  late _MockGoTrueClient auth;

  setUp(() {
    repository = _MockProfileRepository();
    supabase = _MockSupabaseClient();
    auth = _MockGoTrueClient();
    when(() => supabase.auth).thenReturn(auth);
    when(() => auth.currentUser).thenReturn(null);
  });

  ProviderContainer makeContainer() => ProviderContainer.test(
    overrides: [
      profileRepositoryProvider.overrideWithValue(repository),
      supabaseClientProvider.overrideWithValue(supabase),
    ],
  );

  test('seeds the Google display name from the profile shell', () async {
    when(() => repository.getMyProfile()).thenAnswer(
      (_) async => const Right(
        Profile(userId: ProfileUserId('user-1'), displayName: 'Muhammad Saran'),
      ),
    );

    final container = makeContainer();
    addTearDown(container.dispose);

    final state = await container.read(onboardingControllerProvider.future);

    expect(state.displayName, 'Muhammad Saran');
  });

  test('does not show the email profile placeholder as a real name', () async {
    when(() => repository.getMyProfile()).thenAnswer(
      (_) async => const Right(
        Profile(userId: ProfileUserId('user-1'), displayName: 'New User'),
      ),
    );

    final container = makeContainer();
    addTearDown(container.dispose);

    final state = await container.read(onboardingControllerProvider.future);

    expect(state.displayName, isEmpty);
  });

  test('seeds a stored Google avatar into the identity step', () async {
    when(() => repository.getMyProfile()).thenAnswer(
      (_) async => const Right(
        Profile(
          userId: ProfileUserId('user-1'),
          displayName: 'Muhammad Saran',
          avatarUrl: 'https://lh3.googleusercontent.com/example',
        ),
      ),
    );

    final container = makeContainer();
    addTearDown(container.dispose);

    final state = await container.read(onboardingControllerProvider.future);

    expect(state.remoteAvatarUrl, 'https://lh3.googleusercontent.com/example');
  });

  test('prefers a new Google identity name and photo', () async {
    when(() => repository.getMyProfile()).thenAnswer(
      (_) async => const Right(
        Profile(userId: ProfileUserId('user-1'), displayName: 'New User'),
      ),
    );
    when(() => auth.currentUser).thenReturn(
      const User(
        id: 'user-1',
        appMetadata: {},
        userMetadata: {
          'full_name': 'Muhammad Saran Khalid',
          'avatar_url': 'https://lh3.googleusercontent.com/example',
        },
        aud: 'authenticated',
        createdAt: '2026-09-09T00:00:00Z',
      ),
    );

    final container = makeContainer();
    addTearDown(container.dispose);

    final state = await container.read(onboardingControllerProvider.future);

    expect(state.displayName, 'Muhammad Saran Khalid');
    expect(state.remoteAvatarUrl, 'https://lh3.googleusercontent.com/example');
  });
}
