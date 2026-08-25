// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scoring_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Owns live scoring: what the screen sees, and every write it can make.
///
/// Refactored strictly following Clean Architecture:
/// - Presentation Layer knows only the Domain Repository contract (`MatchesRepository`).
/// - All SQLite persistence, write-ahead logging (WAL), and outbox queuing live
///   exclusively inside the Data Layer (`MatchesLocalDataSource` + `MatchesRepositoryImpl`).

@ProviderFor(ScoringController)
final scoringControllerProvider = ScoringControllerFamily._();

/// Owns live scoring: what the screen sees, and every write it can make.
///
/// Refactored strictly following Clean Architecture:
/// - Presentation Layer knows only the Domain Repository contract (`MatchesRepository`).
/// - All SQLite persistence, write-ahead logging (WAL), and outbox queuing live
///   exclusively inside the Data Layer (`MatchesLocalDataSource` + `MatchesRepositoryImpl`).
final class ScoringControllerProvider
    extends $AsyncNotifierProvider<ScoringController, ScoringState> {
  /// Owns live scoring: what the screen sees, and every write it can make.
  ///
  /// Refactored strictly following Clean Architecture:
  /// - Presentation Layer knows only the Domain Repository contract (`MatchesRepository`).
  /// - All SQLite persistence, write-ahead logging (WAL), and outbox queuing live
  ///   exclusively inside the Data Layer (`MatchesLocalDataSource` + `MatchesRepositoryImpl`).
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

String _$scoringControllerHash() => r'45a7dd556f18a8308455abde937b2e9290448fad';

/// Owns live scoring: what the screen sees, and every write it can make.
///
/// Refactored strictly following Clean Architecture:
/// - Presentation Layer knows only the Domain Repository contract (`MatchesRepository`).
/// - All SQLite persistence, write-ahead logging (WAL), and outbox queuing live
///   exclusively inside the Data Layer (`MatchesLocalDataSource` + `MatchesRepositoryImpl`).

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
  /// Refactored strictly following Clean Architecture:
  /// - Presentation Layer knows only the Domain Repository contract (`MatchesRepository`).
  /// - All SQLite persistence, write-ahead logging (WAL), and outbox queuing live
  ///   exclusively inside the Data Layer (`MatchesLocalDataSource` + `MatchesRepositoryImpl`).

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
/// Refactored strictly following Clean Architecture:
/// - Presentation Layer knows only the Domain Repository contract (`MatchesRepository`).
/// - All SQLite persistence, write-ahead logging (WAL), and outbox queuing live
///   exclusively inside the Data Layer (`MatchesLocalDataSource` + `MatchesRepositoryImpl`).

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
