// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_start_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The batting side's XI as a tappable candidate list, derived synchronously
/// from the canonical [MatchRoomSnapshot].

@ProviderFor(matchStartLineup)
final matchStartLineupProvider = MatchStartLineupFamily._();

/// The batting side's XI as a tappable candidate list, derived synchronously
/// from the canonical [MatchRoomSnapshot].

final class MatchStartLineupProvider
    extends
        $FunctionalProvider<
          List<MatchStartLineupCandidate>,
          List<MatchStartLineupCandidate>,
          List<MatchStartLineupCandidate>
        >
    with $Provider<List<MatchStartLineupCandidate>> {
  /// The batting side's XI as a tappable candidate list, derived synchronously
  /// from the canonical [MatchRoomSnapshot].
  MatchStartLineupProvider._({
    required MatchStartLineupFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'matchStartLineupProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$matchStartLineupHash();

  @override
  String toString() {
    return r'matchStartLineupProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<List<MatchStartLineupCandidate>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<MatchStartLineupCandidate> create(Ref ref) {
    final argument = this.argument as String;
    return matchStartLineup(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<MatchStartLineupCandidate> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<MatchStartLineupCandidate>>(
        value,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MatchStartLineupProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$matchStartLineupHash() => r'65baed3be8c52d1c378203e3fe3e6dac8893ea7c';

/// The batting side's XI as a tappable candidate list, derived synchronously
/// from the canonical [MatchRoomSnapshot].

final class MatchStartLineupFamily extends $Family
    with $FunctionalFamilyOverride<List<MatchStartLineupCandidate>, String> {
  MatchStartLineupFamily._()
    : super(
        retry: null,
        name: r'matchStartLineupProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The batting side's XI as a tappable candidate list, derived synchronously
  /// from the canonical [MatchRoomSnapshot].

  MatchStartLineupProvider call(String matchId) =>
      MatchStartLineupProvider._(argument: matchId, from: this);

  @override
  String toString() => r'matchStartLineupProvider';
}

/// The fielding side's XI as a candidate list for the opening bowler slot,
/// derived synchronously from the canonical [MatchRoomSnapshot].

@ProviderFor(matchStartBowlingLineup)
final matchStartBowlingLineupProvider = MatchStartBowlingLineupFamily._();

/// The fielding side's XI as a candidate list for the opening bowler slot,
/// derived synchronously from the canonical [MatchRoomSnapshot].

final class MatchStartBowlingLineupProvider
    extends
        $FunctionalProvider<
          List<MatchStartLineupCandidate>,
          List<MatchStartLineupCandidate>,
          List<MatchStartLineupCandidate>
        >
    with $Provider<List<MatchStartLineupCandidate>> {
  /// The fielding side's XI as a candidate list for the opening bowler slot,
  /// derived synchronously from the canonical [MatchRoomSnapshot].
  MatchStartBowlingLineupProvider._({
    required MatchStartBowlingLineupFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'matchStartBowlingLineupProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$matchStartBowlingLineupHash();

  @override
  String toString() {
    return r'matchStartBowlingLineupProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<List<MatchStartLineupCandidate>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<MatchStartLineupCandidate> create(Ref ref) {
    final argument = this.argument as String;
    return matchStartBowlingLineup(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<MatchStartLineupCandidate> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<MatchStartLineupCandidate>>(
        value,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MatchStartBowlingLineupProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$matchStartBowlingLineupHash() =>
    r'207ba01fcd311bc8d6e5207aa9e35fb6a5a659e7';

/// The fielding side's XI as a candidate list for the opening bowler slot,
/// derived synchronously from the canonical [MatchRoomSnapshot].

final class MatchStartBowlingLineupFamily extends $Family
    with $FunctionalFamilyOverride<List<MatchStartLineupCandidate>, String> {
  MatchStartBowlingLineupFamily._()
    : super(
        retry: null,
        name: r'matchStartBowlingLineupProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The fielding side's XI as a candidate list for the opening bowler slot,
  /// derived synchronously from the canonical [MatchRoomSnapshot].

  MatchStartBowlingLineupProvider call(String matchId) =>
      MatchStartBowlingLineupProvider._(argument: matchId, from: this);

  @override
  String toString() => r'matchStartBowlingLineupProvider';
}
