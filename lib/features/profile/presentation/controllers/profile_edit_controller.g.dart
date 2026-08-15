// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_edit_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ProfileEditController)
final profileEditControllerProvider = ProfileEditControllerProvider._();

final class ProfileEditControllerProvider
    extends $NotifierProvider<ProfileEditController, ProfileEditState> {
  ProfileEditControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileEditControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileEditControllerHash();

  @$internal
  @override
  ProfileEditController create() => ProfileEditController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProfileEditState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProfileEditState>(value),
    );
  }
}

String _$profileEditControllerHash() =>
    r'7c5fdbd417d415583609d8c2d8a17b2e61426950';

abstract class _$ProfileEditController extends $Notifier<ProfileEditState> {
  ProfileEditState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ProfileEditState, ProfileEditState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ProfileEditState, ProfileEditState>,
              ProfileEditState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
