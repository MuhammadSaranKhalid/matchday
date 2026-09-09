// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'completed_match_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Everything the completed-match screen draws, assembled from the ledger.
///
/// One provider rather than one per tab: the four tabs are four views of the
/// same two innings, and fetching per tab would re-read the whole delivery
/// list every time the user switched. The read is O(deliveries) once.

@ProviderFor(completedMatch)
final completedMatchProvider = CompletedMatchFamily._();

/// Everything the completed-match screen draws, assembled from the ledger.
///
/// One provider rather than one per tab: the four tabs are four views of the
/// same two innings, and fetching per tab would re-read the whole delivery
/// list every time the user switched. The read is O(deliveries) once.

final class CompletedMatchProvider
    extends
        $FunctionalProvider<
          AsyncValue<CompletedMatchView>,
          CompletedMatchView,
          FutureOr<CompletedMatchView>
        >
    with
        $FutureModifier<CompletedMatchView>,
        $FutureProvider<CompletedMatchView> {
  /// Everything the completed-match screen draws, assembled from the ledger.
  ///
  /// One provider rather than one per tab: the four tabs are four views of the
  /// same two innings, and fetching per tab would re-read the whole delivery
  /// list every time the user switched. The read is O(deliveries) once.
  CompletedMatchProvider._({
    required CompletedMatchFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'completedMatchProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$completedMatchHash();

  @override
  String toString() {
    return r'completedMatchProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<CompletedMatchView> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CompletedMatchView> create(Ref ref) {
    final argument = this.argument as String;
    return completedMatch(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CompletedMatchProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$completedMatchHash() => r'3cee2e64c30dbe56d8b146040e2423956c2733ca';

/// Everything the completed-match screen draws, assembled from the ledger.
///
/// One provider rather than one per tab: the four tabs are four views of the
/// same two innings, and fetching per tab would re-read the whole delivery
/// list every time the user switched. The read is O(deliveries) once.

final class CompletedMatchFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<CompletedMatchView>, String> {
  CompletedMatchFamily._()
    : super(
        retry: null,
        name: r'completedMatchProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Everything the completed-match screen draws, assembled from the ledger.
  ///
  /// One provider rather than one per tab: the four tabs are four views of the
  /// same two innings, and fetching per tab would re-read the whole delivery
  /// list every time the user switched. The read is O(deliveries) once.

  CompletedMatchProvider call(String matchId) =>
      CompletedMatchProvider._(argument: matchId, from: this);

  @override
  String toString() => r'completedMatchProvider';
}
