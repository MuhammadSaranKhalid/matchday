// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'add_unclaimed_player_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AddUnclaimedPlayerController)
final addUnclaimedPlayerControllerProvider =
    AddUnclaimedPlayerControllerFamily._();

final class AddUnclaimedPlayerControllerProvider
    extends
        $NotifierProvider<
          AddUnclaimedPlayerController,
          AddUnclaimedPlayerState
        > {
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
    r'e23a90648acd8a0b95791f7f4fc68faca123393d';

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

  AddUnclaimedPlayerControllerProvider call(String teamId) =>
      AddUnclaimedPlayerControllerProvider._(argument: teamId, from: this);

  @override
  String toString() => r'addUnclaimedPlayerControllerProvider';
}

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
