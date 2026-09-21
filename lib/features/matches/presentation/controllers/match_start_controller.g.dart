// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_start_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Match Start controller.
///
/// Roles are display-only. Every active control is derived from the same
/// capability system the Edge Function enforces:
///
///   toss:
///     Cricket setup team cricket.match.setup
///     OR match-scoped cricket.match.setup
///
///   lineup/start:
///     batting team cricket.match.setup
///     OR match-scoped cricket.match.setup

@ProviderFor(MatchStartController)
final matchStartControllerProvider = MatchStartControllerFamily._();

/// Match Start controller.
///
/// Roles are display-only. Every active control is derived from the same
/// capability system the Edge Function enforces:
///
///   toss:
///     Cricket setup team cricket.match.setup
///     OR match-scoped cricket.match.setup
///
///   lineup/start:
///     batting team cricket.match.setup
///     OR match-scoped cricket.match.setup
final class MatchStartControllerProvider
    extends $AsyncNotifierProvider<MatchStartController, MatchStartState> {
  /// Match Start controller.
  ///
  /// Roles are display-only. Every active control is derived from the same
  /// capability system the Edge Function enforces:
  ///
  ///   toss:
  ///     Cricket setup team cricket.match.setup
  ///     OR match-scoped cricket.match.setup
  ///
  ///   lineup/start:
  ///     batting team cricket.match.setup
  ///     OR match-scoped cricket.match.setup
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
    r'8a2aa9c738bef4c3403bea1e304221667b9f7425';

/// Match Start controller.
///
/// Roles are display-only. Every active control is derived from the same
/// capability system the Edge Function enforces:
///
///   toss:
///     Cricket setup team cricket.match.setup
///     OR match-scoped cricket.match.setup
///
///   lineup/start:
///     batting team cricket.match.setup
///     OR match-scoped cricket.match.setup

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

  /// Match Start controller.
  ///
  /// Roles are display-only. Every active control is derived from the same
  /// capability system the Edge Function enforces:
  ///
  ///   toss:
  ///     Cricket setup team cricket.match.setup
  ///     OR match-scoped cricket.match.setup
  ///
  ///   lineup/start:
  ///     batting team cricket.match.setup
  ///     OR match-scoped cricket.match.setup

  MatchStartControllerProvider call(String matchId) =>
      MatchStartControllerProvider._(argument: matchId, from: this);

  @override
  String toString() => r'matchStartControllerProvider';
}

/// Match Start controller.
///
/// Roles are display-only. Every active control is derived from the same
/// capability system the Edge Function enforces:
///
///   toss:
///     Cricket setup team cricket.match.setup
///     OR match-scoped cricket.match.setup
///
///   lineup/start:
///     batting team cricket.match.setup
///     OR match-scoped cricket.match.setup

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
