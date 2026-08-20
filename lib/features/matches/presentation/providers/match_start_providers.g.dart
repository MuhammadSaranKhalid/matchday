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

String _$matchStartLineupHash() => r'ef77a146d3ae4d37ee816660af6f6f3dd7947562';

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

/// The Ready stage's screen-ready summary: team names, the toss line, the
/// locked openers resolved to names, and the format line.

@ProviderFor(matchStartReady)
final matchStartReadyProvider = MatchStartReadyFamily._();

/// The Ready stage's screen-ready summary: team names, the toss line, the
/// locked openers resolved to names, and the format line.

final class MatchStartReadyProvider
    extends
        $FunctionalProvider<
          AsyncValue<MatchStartReadyView>,
          MatchStartReadyView,
          FutureOr<MatchStartReadyView>
        >
    with
        $FutureModifier<MatchStartReadyView>,
        $FutureProvider<MatchStartReadyView> {
  /// The Ready stage's screen-ready summary: team names, the toss line, the
  /// locked openers resolved to names, and the format line.
  MatchStartReadyProvider._({
    required MatchStartReadyFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'matchStartReadyProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$matchStartReadyHash();

  @override
  String toString() {
    return r'matchStartReadyProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<MatchStartReadyView> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<MatchStartReadyView> create(Ref ref) {
    final argument = this.argument as String;
    return matchStartReady(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MatchStartReadyProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$matchStartReadyHash() => r'cc82266969d1644f42defb2d39226dfdf59df731';

/// The Ready stage's screen-ready summary: team names, the toss line, the
/// locked openers resolved to names, and the format line.

final class MatchStartReadyFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<MatchStartReadyView>, String> {
  MatchStartReadyFamily._()
    : super(
        retry: null,
        name: r'matchStartReadyProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The Ready stage's screen-ready summary: team names, the toss line, the
  /// locked openers resolved to names, and the format line.

  MatchStartReadyProvider call(String matchId) =>
      MatchStartReadyProvider._(argument: matchId, from: this);

  @override
  String toString() => r'matchStartReadyProvider';
}
