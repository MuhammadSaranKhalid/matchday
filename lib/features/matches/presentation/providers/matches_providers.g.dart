// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'matches_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(matchesRepository)
final matchesRepositoryProvider = MatchesRepositoryProvider._();

final class MatchesRepositoryProvider
    extends
        $FunctionalProvider<
          MatchesRepository,
          MatchesRepository,
          MatchesRepository
        >
    with $Provider<MatchesRepository> {
  MatchesRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'matchesRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$matchesRepositoryHash();

  @$internal
  @override
  $ProviderElement<MatchesRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MatchesRepository create(Ref ref) {
    return matchesRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MatchesRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MatchesRepository>(value),
    );
  }
}

String _$matchesRepositoryHash() => r'3d1a350c84e87c9d4f239d77bf5d38dd69bed1da';

/// The active format presets from the backend catalog (the setup picker reads
/// this instead of a hardcoded list).

@ProviderFor(formatPresets)
final formatPresetsProvider = FormatPresetsProvider._();

/// The active format presets from the backend catalog (the setup picker reads
/// this instead of a hardcoded list).

final class FormatPresetsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<FormatPreset>>,
          List<FormatPreset>,
          FutureOr<List<FormatPreset>>
        >
    with
        $FutureModifier<List<FormatPreset>>,
        $FutureProvider<List<FormatPreset>> {
  /// The active format presets from the backend catalog (the setup picker reads
  /// this instead of a hardcoded list).
  FormatPresetsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'formatPresetsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$formatPresetsHash();

  @$internal
  @override
  $FutureProviderElement<List<FormatPreset>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<FormatPreset>> create(Ref ref) {
    return formatPresets(ref);
  }
}

String _$formatPresetsHash() => r'6855f33bec1e2d342cc476eb7ea94d02996f8ff0';

/// One-shot fetch of a single match (for the request screen). Throws a
/// [FailureWrapper] on error so the UI can show it via AsyncError.

@ProviderFor(match)
final matchProvider = MatchFamily._();

/// One-shot fetch of a single match (for the request screen). Throws a
/// [FailureWrapper] on error so the UI can show it via AsyncError.

final class MatchProvider
    extends $FunctionalProvider<AsyncValue<Match?>, Match?, FutureOr<Match?>>
    with $FutureModifier<Match?>, $FutureProvider<Match?> {
  /// One-shot fetch of a single match (for the request screen). Throws a
  /// [FailureWrapper] on error so the UI can show it via AsyncError.
  MatchProvider._({
    required MatchFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'matchProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$matchHash();

  @override
  String toString() {
    return r'matchProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Match?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Match?> create(Ref ref) {
    final argument = this.argument as String;
    return match(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MatchProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$matchHash() => r'd22a44e6b7834e3ecafed0ddcb3ba66230b55a6b';

/// One-shot fetch of a single match (for the request screen). Throws a
/// [FailureWrapper] on error so the UI can show it via AsyncError.

final class MatchFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Match?>, String> {
  MatchFamily._()
    : super(
        retry: null,
        name: r'matchProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// One-shot fetch of a single match (for the request screen). Throws a
  /// [FailureWrapper] on error so the UI can show it via AsyncError.

  MatchProvider call(String matchId) =>
      MatchProvider._(argument: matchId, from: this);

  @override
  String toString() => r'matchProvider';
}

/// Matches involving the user's teams (for the MATCH tab's requests section).

@ProviderFor(myMatches)
final myMatchesProvider = MyMatchesProvider._();

/// Matches involving the user's teams (for the MATCH tab's requests section).

final class MyMatchesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Match>>,
          List<Match>,
          FutureOr<List<Match>>
        >
    with $FutureModifier<List<Match>>, $FutureProvider<List<Match>> {
  /// Matches involving the user's teams (for the MATCH tab's requests section).
  MyMatchesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myMatchesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myMatchesHash();

  @$internal
  @override
  $FutureProviderElement<List<Match>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Match>> create(Ref ref) {
    return myMatches(ref);
  }
}

String _$myMatchesHash() => r'05974fa29d7172207af6913c9836b9ea06deee33';

/// Live match-row updates (broadcast channel). Each subscription opens its
/// own channel; keep usage to one consumer per route (the Match Start
/// screen + the spectator scoreboard).
///
/// Watching [appResumeCountProvider] rebuilds the subscription whenever the
/// app returns to the foreground — a backgrounded socket is often a zombie,
/// so reconnecting is the only reliable way to know the state is current.

@ProviderFor(liveMatch)
final liveMatchProvider = LiveMatchFamily._();

/// Live match-row updates (broadcast channel). Each subscription opens its
/// own channel; keep usage to one consumer per route (the Match Start
/// screen + the spectator scoreboard).
///
/// Watching [appResumeCountProvider] rebuilds the subscription whenever the
/// app returns to the foreground — a backgrounded socket is often a zombie,
/// so reconnecting is the only reliable way to know the state is current.

final class LiveMatchProvider
    extends $FunctionalProvider<AsyncValue<Match?>, Match?, Stream<Match?>>
    with $FutureModifier<Match?>, $StreamProvider<Match?> {
  /// Live match-row updates (broadcast channel). Each subscription opens its
  /// own channel; keep usage to one consumer per route (the Match Start
  /// screen + the spectator scoreboard).
  ///
  /// Watching [appResumeCountProvider] rebuilds the subscription whenever the
  /// app returns to the foreground — a backgrounded socket is often a zombie,
  /// so reconnecting is the only reliable way to know the state is current.
  LiveMatchProvider._({
    required LiveMatchFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'liveMatchProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$liveMatchHash();

  @override
  String toString() {
    return r'liveMatchProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<Match?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<Match?> create(Ref ref) {
    final argument = this.argument as String;
    return liveMatch(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is LiveMatchProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$liveMatchHash() => r'584dff304f02ed82b7c02d812b9899a90f6bf122';

/// Live match-row updates (broadcast channel). Each subscription opens its
/// own channel; keep usage to one consumer per route (the Match Start
/// screen + the spectator scoreboard).
///
/// Watching [appResumeCountProvider] rebuilds the subscription whenever the
/// app returns to the foreground — a backgrounded socket is often a zombie,
/// so reconnecting is the only reliable way to know the state is current.

final class LiveMatchFamily extends $Family
    with $FunctionalFamilyOverride<Stream<Match?>, String> {
  LiveMatchFamily._()
    : super(
        retry: null,
        name: r'liveMatchProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Live match-row updates (broadcast channel). Each subscription opens its
  /// own channel; keep usage to one consumer per route (the Match Start
  /// screen + the spectator scoreboard).
  ///
  /// Watching [appResumeCountProvider] rebuilds the subscription whenever the
  /// app returns to the foreground — a backgrounded socket is often a zombie,
  /// so reconnecting is the only reliable way to know the state is current.

  LiveMatchProvider call(String matchId) =>
      LiveMatchProvider._(argument: matchId, from: this);

  @override
  String toString() => r'liveMatchProvider';
}

/// The full playing XI for a match (both sides, in batting order where
/// set). Reads from match_players, the per-match polymorphism boundary.
/// Powers bowler / batter / fielder pickers and lineup displays. Returns
/// an empty list if the lineup hasn't been materialised yet.

@ProviderFor(matchPlayers)
final matchPlayersProvider = MatchPlayersFamily._();

/// The full playing XI for a match (both sides, in batting order where
/// set). Reads from match_players, the per-match polymorphism boundary.
/// Powers bowler / batter / fielder pickers and lineup displays. Returns
/// an empty list if the lineup hasn't been materialised yet.

final class MatchPlayersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MatchPlayer>>,
          List<MatchPlayer>,
          FutureOr<List<MatchPlayer>>
        >
    with
        $FutureModifier<List<MatchPlayer>>,
        $FutureProvider<List<MatchPlayer>> {
  /// The full playing XI for a match (both sides, in batting order where
  /// set). Reads from match_players, the per-match polymorphism boundary.
  /// Powers bowler / batter / fielder pickers and lineup displays. Returns
  /// an empty list if the lineup hasn't been materialised yet.
  MatchPlayersProvider._({
    required MatchPlayersFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'matchPlayersProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$matchPlayersHash();

  @override
  String toString() {
    return r'matchPlayersProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<MatchPlayer>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<MatchPlayer>> create(Ref ref) {
    final argument = this.argument as String;
    return matchPlayers(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MatchPlayersProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$matchPlayersHash() => r'86bb903580185239726a7e67f41bb208c0e97ae9';

/// The full playing XI for a match (both sides, in batting order where
/// set). Reads from match_players, the per-match polymorphism boundary.
/// Powers bowler / batter / fielder pickers and lineup displays. Returns
/// an empty list if the lineup hasn't been materialised yet.

final class MatchPlayersFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<MatchPlayer>>, String> {
  MatchPlayersFamily._()
    : super(
        retry: null,
        name: r'matchPlayersProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The full playing XI for a match (both sides, in batting order where
  /// set). Reads from match_players, the per-match polymorphism boundary.
  /// Powers bowler / batter / fielder pickers and lineup displays. Returns
  /// an empty list if the lineup hasn't been materialised yet.

  MatchPlayersProvider call(String matchId) =>
      MatchPlayersProvider._(argument: matchId, from: this);

  @override
  String toString() => r'matchPlayersProvider';
}

/// Live (match, innings) state — striker / non-striker / bowler trio +
/// running totals + optimistic-lock version. Subscribes to the
/// `match:<id>:state` broadcast channel and emits on every
/// `innings_state_updated` event. The scoring screen reads the live trio
/// from here; the spectator scoreboard reads the running totals.

@ProviderFor(liveInningsState)
final liveInningsStateProvider = LiveInningsStateFamily._();

/// Live (match, innings) state — striker / non-striker / bowler trio +
/// running totals + optimistic-lock version. Subscribes to the
/// `match:<id>:state` broadcast channel and emits on every
/// `innings_state_updated` event. The scoring screen reads the live trio
/// from here; the spectator scoreboard reads the running totals.

final class LiveInningsStateProvider
    extends
        $FunctionalProvider<
          AsyncValue<MatchInningsState?>,
          MatchInningsState?,
          Stream<MatchInningsState?>
        >
    with
        $FutureModifier<MatchInningsState?>,
        $StreamProvider<MatchInningsState?> {
  /// Live (match, innings) state — striker / non-striker / bowler trio +
  /// running totals + optimistic-lock version. Subscribes to the
  /// `match:<id>:state` broadcast channel and emits on every
  /// `innings_state_updated` event. The scoring screen reads the live trio
  /// from here; the spectator scoreboard reads the running totals.
  LiveInningsStateProvider._({
    required LiveInningsStateFamily super.from,
    required (String, int) super.argument,
  }) : super(
         retry: null,
         name: r'liveInningsStateProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$liveInningsStateHash();

  @override
  String toString() {
    return r'liveInningsStateProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $StreamProviderElement<MatchInningsState?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<MatchInningsState?> create(Ref ref) {
    final argument = this.argument as (String, int);
    return liveInningsState(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is LiveInningsStateProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$liveInningsStateHash() => r'6cba345ff510539c0dd31e66baa4cf37e7cb6fa4';

/// Live (match, innings) state — striker / non-striker / bowler trio +
/// running totals + optimistic-lock version. Subscribes to the
/// `match:<id>:state` broadcast channel and emits on every
/// `innings_state_updated` event. The scoring screen reads the live trio
/// from here; the spectator scoreboard reads the running totals.

final class LiveInningsStateFamily extends $Family
    with $FunctionalFamilyOverride<Stream<MatchInningsState?>, (String, int)> {
  LiveInningsStateFamily._()
    : super(
        retry: null,
        name: r'liveInningsStateProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Live (match, innings) state — striker / non-striker / bowler trio +
  /// running totals + optimistic-lock version. Subscribes to the
  /// `match:<id>:state` broadcast channel and emits on every
  /// `innings_state_updated` event. The scoring screen reads the live trio
  /// from here; the spectator scoreboard reads the running totals.

  LiveInningsStateProvider call(String matchId, int inningsNumber) =>
      LiveInningsStateProvider._(
        argument: (matchId, inningsNumber),
        from: this,
      );

  @override
  String toString() => r'liveInningsStateProvider';
}

/// Live deliveries for (matchId, inningsNumber) via the broadcast channel.
/// `inningsNumber` is read off the match row; spectators + scorers both
/// subscribe to the same stream.

@ProviderFor(liveBalls)
final liveBallsProvider = LiveBallsFamily._();

/// Live deliveries for (matchId, inningsNumber) via the broadcast channel.
/// `inningsNumber` is read off the match row; spectators + scorers both
/// subscribe to the same stream.

final class LiveBallsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Ball>>,
          List<Ball>,
          Stream<List<Ball>>
        >
    with $FutureModifier<List<Ball>>, $StreamProvider<List<Ball>> {
  /// Live deliveries for (matchId, inningsNumber) via the broadcast channel.
  /// `inningsNumber` is read off the match row; spectators + scorers both
  /// subscribe to the same stream.
  LiveBallsProvider._({
    required LiveBallsFamily super.from,
    required (String, int) super.argument,
  }) : super(
         retry: null,
         name: r'liveBallsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$liveBallsHash();

  @override
  String toString() {
    return r'liveBallsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $StreamProviderElement<List<Ball>> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<Ball>> create(Ref ref) {
    final argument = this.argument as (String, int);
    return liveBalls(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is LiveBallsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$liveBallsHash() => r'7fec9cea6eb7f8601fcb55eb3d69e513a2b03351';

/// Live deliveries for (matchId, inningsNumber) via the broadcast channel.
/// `inningsNumber` is read off the match row; spectators + scorers both
/// subscribe to the same stream.

final class LiveBallsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<Ball>>, (String, int)> {
  LiveBallsFamily._()
    : super(
        retry: null,
        name: r'liveBallsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Live deliveries for (matchId, inningsNumber) via the broadcast channel.
  /// `inningsNumber` is read off the match row; spectators + scorers both
  /// subscribe to the same stream.

  LiveBallsProvider call(String matchId, int inningsNumber) =>
      LiveBallsProvider._(argument: (matchId, inningsNumber), from: this);

  @override
  String toString() => r'liveBallsProvider';
}

/// Whether this device may record deliveries for (match, innings).
///
/// Asks the server rather than deriving it, so the UI gate is the same rule
/// the write path enforces. Re-evaluated on resume and whenever the match row
/// changes — control passes to the other side at the innings break, and the
/// answer flips at exactly that moment.

@ProviderFor(canScoreInnings)
final canScoreInningsProvider = CanScoreInningsFamily._();

/// Whether this device may record deliveries for (match, innings).
///
/// Asks the server rather than deriving it, so the UI gate is the same rule
/// the write path enforces. Re-evaluated on resume and whenever the match row
/// changes — control passes to the other side at the innings break, and the
/// answer flips at exactly that moment.

final class CanScoreInningsProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Whether this device may record deliveries for (match, innings).
  ///
  /// Asks the server rather than deriving it, so the UI gate is the same rule
  /// the write path enforces. Re-evaluated on resume and whenever the match row
  /// changes — control passes to the other side at the innings break, and the
  /// answer flips at exactly that moment.
  CanScoreInningsProvider._({
    required CanScoreInningsFamily super.from,
    required (String, int) super.argument,
  }) : super(
         retry: null,
         name: r'canScoreInningsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$canScoreInningsHash();

  @override
  String toString() {
    return r'canScoreInningsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    final argument = this.argument as (String, int);
    return canScoreInnings(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is CanScoreInningsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$canScoreInningsHash() => r'389cd686934dfadcd99d511f0b39b69b2c643627';

/// Whether this device may record deliveries for (match, innings).
///
/// Asks the server rather than deriving it, so the UI gate is the same rule
/// the write path enforces. Re-evaluated on resume and whenever the match row
/// changes — control passes to the other side at the innings break, and the
/// answer flips at exactly that moment.

final class CanScoreInningsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<bool>, (String, int)> {
  CanScoreInningsFamily._()
    : super(
        retry: null,
        name: r'canScoreInningsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Whether this device may record deliveries for (match, innings).
  ///
  /// Asks the server rather than deriving it, so the UI gate is the same rule
  /// the write path enforces. Re-evaluated on resume and whenever the match row
  /// changes — control passes to the other side at the innings break, and the
  /// answer flips at exactly that moment.

  CanScoreInningsProvider call(String matchId, int inningsNumber) =>
      CanScoreInningsProvider._(argument: (matchId, inningsNumber), from: this);

  @override
  String toString() => r'canScoreInningsProvider';
}

@ProviderFor(myMatchChallenges)
final myMatchChallengesProvider = MyMatchChallengesProvider._();

final class MyMatchChallengesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MatchRequest>>,
          List<MatchRequest>,
          FutureOr<List<MatchRequest>>
        >
    with
        $FutureModifier<List<MatchRequest>>,
        $FutureProvider<List<MatchRequest>> {
  MyMatchChallengesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myMatchChallengesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myMatchChallengesHash();

  @$internal
  @override
  $FutureProviderElement<List<MatchRequest>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<MatchRequest>> create(Ref ref) {
    return myMatchChallenges(ref);
  }
}

String _$myMatchChallengesHash() => r'a6225485655eb47bc405fb198cabb855ef74f626';

@ProviderFor(matchChallenge)
final matchChallengeProvider = MatchChallengeFamily._();

final class MatchChallengeProvider
    extends
        $FunctionalProvider<
          AsyncValue<MatchRequest?>,
          MatchRequest?,
          FutureOr<MatchRequest?>
        >
    with $FutureModifier<MatchRequest?>, $FutureProvider<MatchRequest?> {
  MatchChallengeProvider._({
    required MatchChallengeFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'matchChallengeProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$matchChallengeHash();

  @override
  String toString() {
    return r'matchChallengeProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<MatchRequest?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<MatchRequest?> create(Ref ref) {
    final argument = this.argument as String;
    return matchChallenge(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MatchChallengeProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$matchChallengeHash() => r'aaaa07a7a67a9aee54f095d140d71dd15d0e3f24';

final class MatchChallengeFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<MatchRequest?>, String> {
  MatchChallengeFamily._()
    : super(
        retry: null,
        name: r'matchChallengeProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  MatchChallengeProvider call(String requestId) =>
      MatchChallengeProvider._(argument: requestId, from: this);

  @override
  String toString() => r'matchChallengeProvider';
}

/// Applications received for an open pool challenge.

@ProviderFor(poolApplications)
final poolApplicationsProvider = PoolApplicationsFamily._();

/// Applications received for an open pool challenge.

final class PoolApplicationsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MatchPoolApplication>>,
          List<MatchPoolApplication>,
          FutureOr<List<MatchPoolApplication>>
        >
    with
        $FutureModifier<List<MatchPoolApplication>>,
        $FutureProvider<List<MatchPoolApplication>> {
  /// Applications received for an open pool challenge.
  PoolApplicationsProvider._({
    required PoolApplicationsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'poolApplicationsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$poolApplicationsHash();

  @override
  String toString() {
    return r'poolApplicationsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<MatchPoolApplication>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<MatchPoolApplication>> create(Ref ref) {
    final argument = this.argument as String;
    return poolApplications(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PoolApplicationsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$poolApplicationsHash() => r'91d69551d5fe7a2e5e1b873c278cc6f62efb4447';

/// Applications received for an open pool challenge.

final class PoolApplicationsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<MatchPoolApplication>>,
          String
        > {
  PoolApplicationsFamily._()
    : super(
        retry: null,
        name: r'poolApplicationsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Applications received for an open pool challenge.

  PoolApplicationsProvider call(String requestId) =>
      PoolApplicationsProvider._(argument: requestId, from: this);

  @override
  String toString() => r'poolApplicationsProvider';
}

/// Materialized batting scorecard for an innings (O(1) fast paint).

@ProviderFor(batsmanScorecard)
final batsmanScorecardProvider = BatsmanScorecardFamily._();

/// Materialized batting scorecard for an innings (O(1) fast paint).

final class BatsmanScorecardProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MatchBatsmanStats>>,
          List<MatchBatsmanStats>,
          FutureOr<List<MatchBatsmanStats>>
        >
    with
        $FutureModifier<List<MatchBatsmanStats>>,
        $FutureProvider<List<MatchBatsmanStats>> {
  /// Materialized batting scorecard for an innings (O(1) fast paint).
  BatsmanScorecardProvider._({
    required BatsmanScorecardFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'batsmanScorecardProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$batsmanScorecardHash();

  @override
  String toString() {
    return r'batsmanScorecardProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<MatchBatsmanStats>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<MatchBatsmanStats>> create(Ref ref) {
    final argument = this.argument as String;
    return batsmanScorecard(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is BatsmanScorecardProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$batsmanScorecardHash() => r'69805799e962542e3bb40c25babbf90dc30fdc25';

/// Materialized batting scorecard for an innings (O(1) fast paint).

final class BatsmanScorecardFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<MatchBatsmanStats>>, String> {
  BatsmanScorecardFamily._()
    : super(
        retry: null,
        name: r'batsmanScorecardProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Materialized batting scorecard for an innings (O(1) fast paint).

  BatsmanScorecardProvider call(String inningsId) =>
      BatsmanScorecardProvider._(argument: inningsId, from: this);

  @override
  String toString() => r'batsmanScorecardProvider';
}

/// Materialized bowling scorecard for an innings (O(1) fast paint).

@ProviderFor(bowlerScorecard)
final bowlerScorecardProvider = BowlerScorecardFamily._();

/// Materialized bowling scorecard for an innings (O(1) fast paint).

final class BowlerScorecardProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MatchBowlerStats>>,
          List<MatchBowlerStats>,
          FutureOr<List<MatchBowlerStats>>
        >
    with
        $FutureModifier<List<MatchBowlerStats>>,
        $FutureProvider<List<MatchBowlerStats>> {
  /// Materialized bowling scorecard for an innings (O(1) fast paint).
  BowlerScorecardProvider._({
    required BowlerScorecardFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'bowlerScorecardProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$bowlerScorecardHash();

  @override
  String toString() {
    return r'bowlerScorecardProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<MatchBowlerStats>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<MatchBowlerStats>> create(Ref ref) {
    final argument = this.argument as String;
    return bowlerScorecard(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is BowlerScorecardProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$bowlerScorecardHash() => r'c1b7b161227c7f4a212304c328139d09c2fcafe6';

/// Materialized bowling scorecard for an innings (O(1) fast paint).

final class BowlerScorecardFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<MatchBowlerStats>>, String> {
  BowlerScorecardFamily._()
    : super(
        retry: null,
        name: r'bowlerScorecardProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Materialized bowling scorecard for an innings (O(1) fast paint).

  BowlerScorecardProvider call(String inningsId) =>
      BowlerScorecardProvider._(argument: inningsId, from: this);

  @override
  String toString() => r'bowlerScorecardProvider';
}

/// Wickets fallen for an innings (fall of wickets timeline).

@ProviderFor(inningsWickets)
final inningsWicketsProvider = InningsWicketsFamily._();

/// Wickets fallen for an innings (fall of wickets timeline).

final class InningsWicketsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MatchWicket>>,
          List<MatchWicket>,
          FutureOr<List<MatchWicket>>
        >
    with
        $FutureModifier<List<MatchWicket>>,
        $FutureProvider<List<MatchWicket>> {
  /// Wickets fallen for an innings (fall of wickets timeline).
  InningsWicketsProvider._({
    required InningsWicketsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'inningsWicketsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$inningsWicketsHash();

  @override
  String toString() {
    return r'inningsWicketsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<MatchWicket>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<MatchWicket>> create(Ref ref) {
    final argument = this.argument as String;
    return inningsWickets(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is InningsWicketsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$inningsWicketsHash() => r'b6be0db0fd9c34f12576d50c68b37b308e3eb595';

/// Wickets fallen for an innings (fall of wickets timeline).

final class InningsWicketsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<MatchWicket>>, String> {
  InningsWicketsFamily._()
    : super(
        retry: null,
        name: r'inningsWicketsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Wickets fallen for an innings (fall of wickets timeline).

  InningsWicketsProvider call(String inningsId) =>
      InningsWicketsProvider._(argument: inningsId, from: this);

  @override
  String toString() => r'inningsWicketsProvider';
}
