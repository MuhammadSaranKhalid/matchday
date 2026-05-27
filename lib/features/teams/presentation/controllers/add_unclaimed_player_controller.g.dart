// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'add_unclaimed_player_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Drives the 2-step add-as-unclaimed wizard.
///
/// Pure form state — duplicate-name and jersey-clash detection live in the
/// screen (which has live access to the roster stream). The controller's job
/// is field state + step navigation + submit.

@ProviderFor(AddUnclaimedPlayerController)
final addUnclaimedPlayerControllerProvider =
    AddUnclaimedPlayerControllerFamily._();

/// Drives the 2-step add-as-unclaimed wizard.
///
/// Pure form state — duplicate-name and jersey-clash detection live in the
/// screen (which has live access to the roster stream). The controller's job
/// is field state + step navigation + submit.
final class AddUnclaimedPlayerControllerProvider
    extends
        $NotifierProvider<
          AddUnclaimedPlayerController,
          AddUnclaimedPlayerState
        > {
  /// Drives the 2-step add-as-unclaimed wizard.
  ///
  /// Pure form state — duplicate-name and jersey-clash detection live in the
  /// screen (which has live access to the roster stream). The controller's job
  /// is field state + step navigation + submit.
  AddUnclaimedPlayerControllerProvider._({
    required AddUnclaimedPlayerControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'addUnclaimedPlayerControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$addUnclaimedPlayerControllerHash();

  @override
  String toString() {
    return r'addUnclaimedPlayerControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  AddUnclaimedPlayerController create() => AddUnclaimedPlayerController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AddUnclaimedPlayerState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AddUnclaimedPlayerState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AddUnclaimedPlayerControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$addUnclaimedPlayerControllerHash() =>
    r'44104fe1232c7372c06037150ec4ead4d6a4e839';

/// Drives the 2-step add-as-unclaimed wizard.
///
/// Pure form state — duplicate-name and jersey-clash detection live in the
/// screen (which has live access to the roster stream). The controller's job
/// is field state + step navigation + submit.

final class AddUnclaimedPlayerControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          AddUnclaimedPlayerController,
          AddUnclaimedPlayerState,
          AddUnclaimedPlayerState,
          AddUnclaimedPlayerState,
          String
        > {
  AddUnclaimedPlayerControllerFamily._()
    : super(
        retry: null,
        name: r'addUnclaimedPlayerControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Drives the 2-step add-as-unclaimed wizard.
  ///
  /// Pure form state — duplicate-name and jersey-clash detection live in the
  /// screen (which has live access to the roster stream). The controller's job
  /// is field state + step navigation + submit.

  AddUnclaimedPlayerControllerProvider call(String teamId) =>
      AddUnclaimedPlayerControllerProvider._(argument: teamId, from: this);

  @override
  String toString() => r'addUnclaimedPlayerControllerProvider';
}

/// Drives the 2-step add-as-unclaimed wizard.
///
/// Pure form state — duplicate-name and jersey-clash detection live in the
/// screen (which has live access to the roster stream). The controller's job
/// is field state + step navigation + submit.

abstract class _$AddUnclaimedPlayerController
    extends $Notifier<AddUnclaimedPlayerState> {
  late final _$args = ref.$arg as String;
  String get teamId => _$args;

  AddUnclaimedPlayerState build(String teamId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AddUnclaimedPlayerState, AddUnclaimedPlayerState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AddUnclaimedPlayerState, AddUnclaimedPlayerState>,
              AddUnclaimedPlayerState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
