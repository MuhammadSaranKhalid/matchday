// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_start_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The batting side's XI as a tappable candidate list, in batting order as
/// materialised in `match_players`.
///
/// Every player in the XI is included, whether or not they appear on the
/// team's permanent roster. Guests and one-off ringers are materialised into
/// `match_players` without a `team_members` row, and an inner join here would
/// make them silently unpickable — a player who is physically opening the
/// batting but cannot be selected in the app.

@ProviderFor(matchStartLineup)
final matchStartLineupProvider = MatchStartLineupFamily._();

/// The batting side's XI as a tappable candidate list, in batting order as
/// materialised in `match_players`.
///
/// Every player in the XI is included, whether or not they appear on the
/// team's permanent roster. Guests and one-off ringers are materialised into
/// `match_players` without a `team_members` row, and an inner join here would
/// make them silently unpickable — a player who is physically opening the
/// batting but cannot be selected in the app.

final class MatchStartLineupProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MatchStartLineupCandidate>>,
          List<MatchStartLineupCandidate>,
          FutureOr<List<MatchStartLineupCandidate>>
        >
    with
        $FutureModifier<List<MatchStartLineupCandidate>>,
        $FutureProvider<List<MatchStartLineupCandidate>> {
  /// The batting side's XI as a tappable candidate list, in batting order as
  /// materialised in `match_players`.
  ///
  /// Every player in the XI is included, whether or not they appear on the
  /// team's permanent roster. Guests and one-off ringers are materialised into
  /// `match_players` without a `team_members` row, and an inner join here would
  /// make them silently unpickable — a player who is physically opening the
  /// batting but cannot be selected in the app.
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
  $FutureProviderElement<List<MatchStartLineupCandidate>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<MatchStartLineupCandidate>> create(Ref ref) {
    final argument = this.argument as String;
    return matchStartLineup(ref, argument);
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

String _$matchStartLineupHash() => r'51963cf2b9ac51cf8a29d83d8835f48b07ab7ccb';

/// The batting side's XI as a tappable candidate list, in batting order as
/// materialised in `match_players`.
///
/// Every player in the XI is included, whether or not they appear on the
/// team's permanent roster. Guests and one-off ringers are materialised into
/// `match_players` without a `team_members` row, and an inner join here would
/// make them silently unpickable — a player who is physically opening the
/// batting but cannot be selected in the app.

final class MatchStartLineupFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<MatchStartLineupCandidate>>,
          String
        > {
  MatchStartLineupFamily._()
    : super(
        retry: null,
        name: r'matchStartLineupProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The batting side's XI as a tappable candidate list, in batting order as
  /// materialised in `match_players`.
  ///
  /// Every player in the XI is included, whether or not they appear on the
  /// team's permanent roster. Guests and one-off ringers are materialised into
  /// `match_players` without a `team_members` row, and an inner join here would
  /// make them silently unpickable — a player who is physically opening the
  /// batting but cannot be selected in the app.

  MatchStartLineupProvider call(String matchId) =>
      MatchStartLineupProvider._(argument: matchId, from: this);

  @override
  String toString() => r'matchStartLineupProvider';
}

/// The fielding side's XI as a candidate list for the opening bowler slot.

@ProviderFor(matchStartBowlingLineup)
final matchStartBowlingLineupProvider = MatchStartBowlingLineupFamily._();

/// The fielding side's XI as a candidate list for the opening bowler slot.

final class MatchStartBowlingLineupProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MatchStartLineupCandidate>>,
          List<MatchStartLineupCandidate>,
          FutureOr<List<MatchStartLineupCandidate>>
        >
    with
        $FutureModifier<List<MatchStartLineupCandidate>>,
        $FutureProvider<List<MatchStartLineupCandidate>> {
  /// The fielding side's XI as a candidate list for the opening bowler slot.
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
  $FutureProviderElement<List<MatchStartLineupCandidate>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<MatchStartLineupCandidate>> create(Ref ref) {
    final argument = this.argument as String;
    return matchStartBowlingLineup(ref, argument);
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
    r'18b8c6df6097b8b9ebd5f9a3c0557c124292f68e';

/// The fielding side's XI as a candidate list for the opening bowler slot.

final class MatchStartBowlingLineupFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<MatchStartLineupCandidate>>,
          String
        > {
  MatchStartBowlingLineupFamily._()
    : super(
        retry: null,
        name: r'matchStartBowlingLineupProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The fielding side's XI as a candidate list for the opening bowler slot.

  MatchStartBowlingLineupProvider call(String matchId) =>
      MatchStartBowlingLineupProvider._(argument: matchId, from: this);

  @override
  String toString() => r'matchStartBowlingLineupProvider';
}
