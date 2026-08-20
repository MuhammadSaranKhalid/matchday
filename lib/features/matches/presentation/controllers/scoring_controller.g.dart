// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scoring_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Owns live scoring: what the screen sees, and every write it can make.
///
/// Extracted from `ScoringScreen`, which had grown to hold the on-field state,
/// the cricket rules, and the RPC dispatch inside one 3,400-line widget. None
/// of that was reachable from a unit test — which is how a wide-attribution
/// bug that corrupted scorecards survived in it.

@ProviderFor(ScoringController)
final scoringControllerProvider = ScoringControllerFamily._();

/// Owns live scoring: what the screen sees, and every write it can make.
///
/// Extracted from `ScoringScreen`, which had grown to hold the on-field state,
/// the cricket rules, and the RPC dispatch inside one 3,400-line widget. None
/// of that was reachable from a unit test — which is how a wide-attribution
/// bug that corrupted scorecards survived in it.
final class ScoringControllerProvider
    extends $AsyncNotifierProvider<ScoringController, ScoringState> {
  /// Owns live scoring: what the screen sees, and every write it can make.
  ///
  /// Extracted from `ScoringScreen`, which had grown to hold the on-field state,
  /// the cricket rules, and the RPC dispatch inside one 3,400-line widget. None
  /// of that was reachable from a unit test — which is how a wide-attribution
  /// bug that corrupted scorecards survived in it.
  ScoringControllerProvider._({
    required ScoringControllerFamily super.from,
    required (String, int) super.argument,
  }) : super(
         retry: null,
         name: r'scoringControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$scoringControllerHash();

  @override
  String toString() {
    return r'scoringControllerProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  ScoringController create() => ScoringController();

  @override
  bool operator ==(Object other) {
    return other is ScoringControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$scoringControllerHash() => r'4c4bd0e4207615053f10a0748b37c85cb1b0bc62';

/// Owns live scoring: what the screen sees, and every write it can make.
///
/// Extracted from `ScoringScreen`, which had grown to hold the on-field state,
/// the cricket rules, and the RPC dispatch inside one 3,400-line widget. None
/// of that was reachable from a unit test — which is how a wide-attribution
/// bug that corrupted scorecards survived in it.

final class ScoringControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          ScoringController,
          AsyncValue<ScoringState>,
          ScoringState,
          FutureOr<ScoringState>,
          (String, int)
        > {
  ScoringControllerFamily._()
    : super(
        retry: null,
        name: r'scoringControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Owns live scoring: what the screen sees, and every write it can make.
  ///
  /// Extracted from `ScoringScreen`, which had grown to hold the on-field state,
  /// the cricket rules, and the RPC dispatch inside one 3,400-line widget. None
  /// of that was reachable from a unit test — which is how a wide-attribution
  /// bug that corrupted scorecards survived in it.

  ScoringControllerProvider call(String matchId, int inningsNumber) =>
      ScoringControllerProvider._(
        argument: (matchId, inningsNumber),
        from: this,
      );

  @override
  String toString() => r'scoringControllerProvider';
}

/// Owns live scoring: what the screen sees, and every write it can make.
///
/// Extracted from `ScoringScreen`, which had grown to hold the on-field state,
/// the cricket rules, and the RPC dispatch inside one 3,400-line widget. None
/// of that was reachable from a unit test — which is how a wide-attribution
/// bug that corrupted scorecards survived in it.

abstract class _$ScoringController extends $AsyncNotifier<ScoringState> {
  late final _$args = ref.$arg as (String, int);
  String get matchId => _$args.$1;
  int get inningsNumber => _$args.$2;

  FutureOr<ScoringState> build(String matchId, int inningsNumber);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<ScoringState>, ScoringState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ScoringState>, ScoringState>,
              AsyncValue<ScoringState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args.$1, _$args.$2));
  }
}
