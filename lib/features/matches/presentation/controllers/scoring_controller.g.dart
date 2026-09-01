// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scoring_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// What the scoring screen sees, and every write it can make.
///
/// Deliberately thin. Everything about HOW a delivery reaches the server — the
/// queue, the write-ahead log, retries, what is provisional and what is
/// confirmed — belongs to [ScoringSession] in the data layer. This class turns
/// taps into drafts, applies the guards whose failure the scorer needs to read
/// as a sentence, and republishes the session's projection as screen state.

@ProviderFor(ScoringController)
final scoringControllerProvider = ScoringControllerFamily._();

/// What the scoring screen sees, and every write it can make.
///
/// Deliberately thin. Everything about HOW a delivery reaches the server — the
/// queue, the write-ahead log, retries, what is provisional and what is
/// confirmed — belongs to [ScoringSession] in the data layer. This class turns
/// taps into drafts, applies the guards whose failure the scorer needs to read
/// as a sentence, and republishes the session's projection as screen state.
final class ScoringControllerProvider
    extends $AsyncNotifierProvider<ScoringController, ScoringState> {
  /// What the scoring screen sees, and every write it can make.
  ///
  /// Deliberately thin. Everything about HOW a delivery reaches the server — the
  /// queue, the write-ahead log, retries, what is provisional and what is
  /// confirmed — belongs to [ScoringSession] in the data layer. This class turns
  /// taps into drafts, applies the guards whose failure the scorer needs to read
  /// as a sentence, and republishes the session's projection as screen state.
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

String _$scoringControllerHash() => r'8b375ae46d2ee23c65f29036f8b84fac9fcbe8b0';

/// What the scoring screen sees, and every write it can make.
///
/// Deliberately thin. Everything about HOW a delivery reaches the server — the
/// queue, the write-ahead log, retries, what is provisional and what is
/// confirmed — belongs to [ScoringSession] in the data layer. This class turns
/// taps into drafts, applies the guards whose failure the scorer needs to read
/// as a sentence, and republishes the session's projection as screen state.

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

  /// What the scoring screen sees, and every write it can make.
  ///
  /// Deliberately thin. Everything about HOW a delivery reaches the server — the
  /// queue, the write-ahead log, retries, what is provisional and what is
  /// confirmed — belongs to [ScoringSession] in the data layer. This class turns
  /// taps into drafts, applies the guards whose failure the scorer needs to read
  /// as a sentence, and republishes the session's projection as screen state.

  ScoringControllerProvider call(String matchId, int inningsNumber) =>
      ScoringControllerProvider._(
        argument: (matchId, inningsNumber),
        from: this,
      );

  @override
  String toString() => r'scoringControllerProvider';
}

/// What the scoring screen sees, and every write it can make.
///
/// Deliberately thin. Everything about HOW a delivery reaches the server — the
/// queue, the write-ahead log, retries, what is provisional and what is
/// confirmed — belongs to [ScoringSession] in the data layer. This class turns
/// taps into drafts, applies the guards whose failure the scorer needs to read
/// as a sentence, and republishes the session's projection as screen state.

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
