// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_setup_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Drives the 6-step match-setup wizard for a given team A. AsyncNotifier so
/// [build] restores a persisted draft first (mirrors the other wizards).

@ProviderFor(MatchSetupController)
final matchSetupControllerProvider = MatchSetupControllerFamily._();

/// Drives the 6-step match-setup wizard for a given team A. AsyncNotifier so
/// [build] restores a persisted draft first (mirrors the other wizards).
final class MatchSetupControllerProvider
    extends $AsyncNotifierProvider<MatchSetupController, MatchSetupState> {
  /// Drives the 6-step match-setup wizard for a given team A. AsyncNotifier so
  /// [build] restores a persisted draft first (mirrors the other wizards).
  MatchSetupControllerProvider._({
    required MatchSetupControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'matchSetupControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$matchSetupControllerHash();

  @override
  String toString() {
    return r'matchSetupControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  MatchSetupController create() => MatchSetupController();

  @override
  bool operator ==(Object other) {
    return other is MatchSetupControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$matchSetupControllerHash() =>
    r'c10e7a0a90e7858a6b44253a30fdd1109e11887f';

/// Drives the 6-step match-setup wizard for a given team A. AsyncNotifier so
/// [build] restores a persisted draft first (mirrors the other wizards).

final class MatchSetupControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          MatchSetupController,
          AsyncValue<MatchSetupState>,
          MatchSetupState,
          FutureOr<MatchSetupState>,
          String
        > {
  MatchSetupControllerFamily._()
    : super(
        retry: null,
        name: r'matchSetupControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Drives the 6-step match-setup wizard for a given team A. AsyncNotifier so
  /// [build] restores a persisted draft first (mirrors the other wizards).

  MatchSetupControllerProvider call(String teamAId) =>
      MatchSetupControllerProvider._(argument: teamAId, from: this);

  @override
  String toString() => r'matchSetupControllerProvider';
}

/// Drives the 6-step match-setup wizard for a given team A. AsyncNotifier so
/// [build] restores a persisted draft first (mirrors the other wizards).

abstract class _$MatchSetupController extends $AsyncNotifier<MatchSetupState> {
  late final _$args = ref.$arg as String;
  String get teamAId => _$args;

  FutureOr<MatchSetupState> build(String teamAId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<MatchSetupState>, MatchSetupState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<MatchSetupState>, MatchSetupState>,
              AsyncValue<MatchSetupState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
