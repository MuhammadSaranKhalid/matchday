// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'matches_board_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(MatchesBoardTabController)
final matchesBoardTabControllerProvider = MatchesBoardTabControllerProvider._();

final class MatchesBoardTabControllerProvider
    extends $NotifierProvider<MatchesBoardTabController, MatchesBoardTab> {
  MatchesBoardTabControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'matchesBoardTabControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$matchesBoardTabControllerHash();

  @$internal
  @override
  MatchesBoardTabController create() => MatchesBoardTabController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MatchesBoardTab value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MatchesBoardTab>(value),
    );
  }
}

String _$matchesBoardTabControllerHash() =>
    r'3a613060a7c35eec88159abdb67453890a9e551c';

abstract class _$MatchesBoardTabController extends $Notifier<MatchesBoardTab> {
  MatchesBoardTab build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<MatchesBoardTab, MatchesBoardTab>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<MatchesBoardTab, MatchesBoardTab>,
              MatchesBoardTab,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// The whole board for [tab], grouped by competition.

@ProviderFor(matchesBoard)
final matchesBoardProvider = MatchesBoardFamily._();

/// The whole board for [tab], grouped by competition.

final class MatchesBoardProvider
    extends
        $FunctionalProvider<
          AsyncValue<MatchesBoardView>,
          MatchesBoardView,
          FutureOr<MatchesBoardView>
        >
    with $FutureModifier<MatchesBoardView>, $FutureProvider<MatchesBoardView> {
  /// The whole board for [tab], grouped by competition.
  MatchesBoardProvider._({
    required MatchesBoardFamily super.from,
    required MatchesBoardTab super.argument,
  }) : super(
         retry: null,
         name: r'matchesBoardProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$matchesBoardHash();

  @override
  String toString() {
    return r'matchesBoardProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<MatchesBoardView> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<MatchesBoardView> create(Ref ref) {
    final argument = this.argument as MatchesBoardTab;
    return matchesBoard(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MatchesBoardProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$matchesBoardHash() => r'cfd2f240e4ea19b6c7bf2733ee39f15b7595897d';

/// The whole board for [tab], grouped by competition.

final class MatchesBoardFamily extends $Family
    with
        $FunctionalFamilyOverride<FutureOr<MatchesBoardView>, MatchesBoardTab> {
  MatchesBoardFamily._()
    : super(
        retry: null,
        name: r'matchesBoardProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The whole board for [tab], grouped by competition.

  MatchesBoardProvider call(MatchesBoardTab tab) =>
      MatchesBoardProvider._(argument: tab, from: this);

  @override
  String toString() => r'matchesBoardProvider';
}
