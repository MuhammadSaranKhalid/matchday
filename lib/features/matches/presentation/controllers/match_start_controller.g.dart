// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_start_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Watches the match row in real time and exposes the three Match Start
/// action methods. The `build()` stream-aware shape means widgets get an
/// [AsyncValue] that updates without manual refresh as the other captain
/// progresses through stages.

@ProviderFor(MatchStartController)
final matchStartControllerProvider = MatchStartControllerFamily._();

/// Watches the match row in real time and exposes the three Match Start
/// action methods. The `build()` stream-aware shape means widgets get an
/// [AsyncValue] that updates without manual refresh as the other captain
/// progresses through stages.
final class MatchStartControllerProvider
    extends $AsyncNotifierProvider<MatchStartController, MatchStartState> {
  /// Watches the match row in real time and exposes the three Match Start
  /// action methods. The `build()` stream-aware shape means widgets get an
  /// [AsyncValue] that updates without manual refresh as the other captain
  /// progresses through stages.
  MatchStartControllerProvider._({
    required MatchStartControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'matchStartControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$matchStartControllerHash();

  @override
  String toString() {
    return r'matchStartControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  MatchStartController create() => MatchStartController();

  @override
  bool operator ==(Object other) {
    return other is MatchStartControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$matchStartControllerHash() =>
    r'b5751e935bdfdb1b5a157443ddfee5304e6ecfca';

/// Watches the match row in real time and exposes the three Match Start
/// action methods. The `build()` stream-aware shape means widgets get an
/// [AsyncValue] that updates without manual refresh as the other captain
/// progresses through stages.

final class MatchStartControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          MatchStartController,
          AsyncValue<MatchStartState>,
          MatchStartState,
          FutureOr<MatchStartState>,
          String
        > {
  MatchStartControllerFamily._()
    : super(
        retry: null,
        name: r'matchStartControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Watches the match row in real time and exposes the three Match Start
  /// action methods. The `build()` stream-aware shape means widgets get an
  /// [AsyncValue] that updates without manual refresh as the other captain
  /// progresses through stages.

  MatchStartControllerProvider call(String matchId) =>
      MatchStartControllerProvider._(argument: matchId, from: this);

  @override
  String toString() => r'matchStartControllerProvider';
}

/// Watches the match row in real time and exposes the three Match Start
/// action methods. The `build()` stream-aware shape means widgets get an
/// [AsyncValue] that updates without manual refresh as the other captain
/// progresses through stages.

abstract class _$MatchStartController extends $AsyncNotifier<MatchStartState> {
  late final _$args = ref.$arg as String;
  String get matchId => _$args;

  FutureOr<MatchStartState> build(String matchId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<MatchStartState>, MatchStartState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<MatchStartState>, MatchStartState>,
              AsyncValue<MatchStartState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
