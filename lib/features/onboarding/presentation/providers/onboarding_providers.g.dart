// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(profileRepository)
final profileRepositoryProvider = ProfileRepositoryProvider._();

final class ProfileRepositoryProvider
    extends
        $FunctionalProvider<
          ProfileRepository,
          ProfileRepository,
          ProfileRepository
        >
    with $Provider<ProfileRepository> {
  ProfileRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileRepositoryHash();

  @$internal
  @override
  $ProviderElement<ProfileRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ProfileRepository create(Ref ref) {
    return profileRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProfileRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProfileRepository>(value),
    );
  }
}

String _$profileRepositoryHash() => r'630ed8c89d63247225ad8f1874ab1b664f3764c4';

@ProviderFor(avatarPicker)
final avatarPickerProvider = AvatarPickerProvider._();

final class AvatarPickerProvider
    extends $FunctionalProvider<AvatarPicker, AvatarPicker, AvatarPicker>
    with $Provider<AvatarPicker> {
  AvatarPickerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'avatarPickerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$avatarPickerHash();

  @$internal
  @override
  $ProviderElement<AvatarPicker> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AvatarPicker create(Ref ref) {
    return avatarPicker(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AvatarPicker value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AvatarPicker>(value),
    );
  }
}

String _$avatarPickerHash() => r'b24e2d75459a925011b3526f5bb3475f41d2adc2';

/// Whether the signed-in user has finished onboarding (has a username).
///
/// The router's redirect reads this via `.value` to gate `/onboarding`. It
/// depends on [currentUserStreamProvider] so it recomputes on sign-in/out, and
/// is invalidated by the onboarding controller when the user finishes, which
/// pokes the router's refreshListenable to re-run the redirect.

@ProviderFor(onboardingStatus)
final onboardingStatusProvider = OnboardingStatusProvider._();

/// Whether the signed-in user has finished onboarding (has a username).
///
/// The router's redirect reads this via `.value` to gate `/onboarding`. It
/// depends on [currentUserStreamProvider] so it recomputes on sign-in/out, and
/// is invalidated by the onboarding controller when the user finishes, which
/// pokes the router's refreshListenable to re-run the redirect.

final class OnboardingStatusProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Whether the signed-in user has finished onboarding (has a username).
  ///
  /// The router's redirect reads this via `.value` to gate `/onboarding`. It
  /// depends on [currentUserStreamProvider] so it recomputes on sign-in/out, and
  /// is invalidated by the onboarding controller when the user finishes, which
  /// pokes the router's refreshListenable to re-run the redirect.
  OnboardingStatusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'onboardingStatusProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$onboardingStatusHash();

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    return onboardingStatus(ref);
  }
}

String _$onboardingStatusHash() => r'1d5f9171f54620515913d206ff33f319fe949a5c';

/// The signed-in user's profile, for the Pavilion header. Throws a
/// [FailureWrapper] on error so the UI can render it via AsyncError.
/// keepAlive so it's fetched once and shared, not refetched per screen.

@ProviderFor(myProfile)
final myProfileProvider = MyProfileProvider._();

/// The signed-in user's profile, for the Pavilion header. Throws a
/// [FailureWrapper] on error so the UI can render it via AsyncError.
/// keepAlive so it's fetched once and shared, not refetched per screen.

final class MyProfileProvider
    extends
        $FunctionalProvider<AsyncValue<Profile?>, Profile?, FutureOr<Profile?>>
    with $FutureModifier<Profile?>, $FutureProvider<Profile?> {
  /// The signed-in user's profile, for the Pavilion header. Throws a
  /// [FailureWrapper] on error so the UI can render it via AsyncError.
  /// keepAlive so it's fetched once and shared, not refetched per screen.
  MyProfileProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myProfileProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myProfileHash();

  @$internal
  @override
  $FutureProviderElement<Profile?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Profile?> create(Ref ref) {
    return myProfile(ref);
  }
}

String _$myProfileHash() => r'2ee4065620f7d001fa0647ccdd6a52f358b3246a';

/// Any user's public profile by [username] — backs the `/u/:username` route
/// and shared-link landing (a tapped `joinmatchday.com/u/<username>` opens
/// here). Resolves to null when the username isn't found, so the screen can
/// render a "not found" state. Throws a [FailureWrapper] on a fetch error
/// (rendered via AsyncError). Autodispose: a viewed profile shouldn't pin
/// memory once the screen is gone.

@ProviderFor(profileByUsername)
final profileByUsernameProvider = ProfileByUsernameFamily._();

/// Any user's public profile by [username] — backs the `/u/:username` route
/// and shared-link landing (a tapped `joinmatchday.com/u/<username>` opens
/// here). Resolves to null when the username isn't found, so the screen can
/// render a "not found" state. Throws a [FailureWrapper] on a fetch error
/// (rendered via AsyncError). Autodispose: a viewed profile shouldn't pin
/// memory once the screen is gone.

final class ProfileByUsernameProvider
    extends
        $FunctionalProvider<AsyncValue<Profile?>, Profile?, FutureOr<Profile?>>
    with $FutureModifier<Profile?>, $FutureProvider<Profile?> {
  /// Any user's public profile by [username] — backs the `/u/:username` route
  /// and shared-link landing (a tapped `joinmatchday.com/u/<username>` opens
  /// here). Resolves to null when the username isn't found, so the screen can
  /// render a "not found" state. Throws a [FailureWrapper] on a fetch error
  /// (rendered via AsyncError). Autodispose: a viewed profile shouldn't pin
  /// memory once the screen is gone.
  ProfileByUsernameProvider._({
    required ProfileByUsernameFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'profileByUsernameProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$profileByUsernameHash();

  @override
  String toString() {
    return r'profileByUsernameProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Profile?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Profile?> create(Ref ref) {
    final argument = this.argument as String;
    return profileByUsername(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ProfileByUsernameProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$profileByUsernameHash() => r'd49aca415bc4d3fa96d535cc4c7b7aa425d9e493';

/// Any user's public profile by [username] — backs the `/u/:username` route
/// and shared-link landing (a tapped `joinmatchday.com/u/<username>` opens
/// here). Resolves to null when the username isn't found, so the screen can
/// render a "not found" state. Throws a [FailureWrapper] on a fetch error
/// (rendered via AsyncError). Autodispose: a viewed profile shouldn't pin
/// memory once the screen is gone.

final class ProfileByUsernameFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Profile?>, String> {
  ProfileByUsernameFamily._()
    : super(
        retry: null,
        name: r'profileByUsernameProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Any user's public profile by [username] — backs the `/u/:username` route
  /// and shared-link landing (a tapped `joinmatchday.com/u/<username>` opens
  /// here). Resolves to null when the username isn't found, so the screen can
  /// render a "not found" state. Throws a [FailureWrapper] on a fetch error
  /// (rendered via AsyncError). Autodispose: a viewed profile shouldn't pin
  /// memory once the screen is gone.

  ProfileByUsernameProvider call(String username) =>
      ProfileByUsernameProvider._(argument: username, from: this);

  @override
  String toString() => r'profileByUsernameProvider';
}
