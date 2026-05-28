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

String _$matchesRepositoryHash() => r'a316d956792168308175a04fa059c37a6016b84c';

@ProviderFor(listMyMatchesUseCase)
final listMyMatchesUseCaseProvider = ListMyMatchesUseCaseProvider._();

final class ListMyMatchesUseCaseProvider
    extends $FunctionalProvider<ListMyMatches, ListMyMatches, ListMyMatches>
    with $Provider<ListMyMatches> {
  ListMyMatchesUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'listMyMatchesUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$listMyMatchesUseCaseHash();

  @$internal
  @override
  $ProviderElement<ListMyMatches> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ListMyMatches create(Ref ref) {
    return listMyMatchesUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ListMyMatches value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ListMyMatches>(value),
    );
  }
}

String _$listMyMatchesUseCaseHash() =>
    r'7baedb80f4d5c56400a19fbc365ea97f3fc6987b';

@ProviderFor(getMatchUseCase)
final getMatchUseCaseProvider = GetMatchUseCaseProvider._();

final class GetMatchUseCaseProvider
    extends $FunctionalProvider<GetMatch, GetMatch, GetMatch>
    with $Provider<GetMatch> {
  GetMatchUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'getMatchUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$getMatchUseCaseHash();

  @$internal
  @override
  $ProviderElement<GetMatch> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GetMatch create(Ref ref) {
    return getMatchUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetMatch value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetMatch>(value),
    );
  }
}

String _$getMatchUseCaseHash() => r'37914fa256a0d840f12e73f2c5e5296ba57b1462';

@ProviderFor(completeMatchUseCase)
final completeMatchUseCaseProvider = CompleteMatchUseCaseProvider._();

final class CompleteMatchUseCaseProvider
    extends $FunctionalProvider<CompleteMatch, CompleteMatch, CompleteMatch>
    with $Provider<CompleteMatch> {
  CompleteMatchUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'completeMatchUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$completeMatchUseCaseHash();

  @$internal
  @override
  $ProviderElement<CompleteMatch> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CompleteMatch create(Ref ref) {
    return completeMatchUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CompleteMatch value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CompleteMatch>(value),
    );
  }
}

String _$completeMatchUseCaseHash() =>
    r'b57b71cf4c0e7f5e0ad0a84d6f8fffbe0082e861';

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

String _$matchHash() => r'c8cfa6f9701e9cde9c539a2357ad1e749e49222e';

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

String _$myMatchesHash() => r'50ca81e8fc13b47109848645883433c1213c3b10';

@ProviderFor(watchMatchUseCase)
final watchMatchUseCaseProvider = WatchMatchUseCaseProvider._();

final class WatchMatchUseCaseProvider
    extends $FunctionalProvider<WatchMatch, WatchMatch, WatchMatch>
    with $Provider<WatchMatch> {
  WatchMatchUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'watchMatchUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$watchMatchUseCaseHash();

  @$internal
  @override
  $ProviderElement<WatchMatch> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  WatchMatch create(Ref ref) {
    return watchMatchUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WatchMatch value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WatchMatch>(value),
    );
  }
}

String _$watchMatchUseCaseHash() => r'05618fe58ffdfb86a10e0348865d9bbbbdbf0007';

@ProviderFor(recordMatchTossUseCase)
final recordMatchTossUseCaseProvider = RecordMatchTossUseCaseProvider._();

final class RecordMatchTossUseCaseProvider
    extends
        $FunctionalProvider<RecordMatchToss, RecordMatchToss, RecordMatchToss>
    with $Provider<RecordMatchToss> {
  RecordMatchTossUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recordMatchTossUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recordMatchTossUseCaseHash();

  @$internal
  @override
  $ProviderElement<RecordMatchToss> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RecordMatchToss create(Ref ref) {
    return recordMatchTossUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RecordMatchToss value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RecordMatchToss>(value),
    );
  }
}

String _$recordMatchTossUseCaseHash() =>
    r'e15c4079c4bca3db3a51aab9a085726b0e1a5849';

@ProviderFor(submitMatchOpenersUseCase)
final submitMatchOpenersUseCaseProvider = SubmitMatchOpenersUseCaseProvider._();

final class SubmitMatchOpenersUseCaseProvider
    extends
        $FunctionalProvider<
          SubmitMatchOpeners,
          SubmitMatchOpeners,
          SubmitMatchOpeners
        >
    with $Provider<SubmitMatchOpeners> {
  SubmitMatchOpenersUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'submitMatchOpenersUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$submitMatchOpenersUseCaseHash();

  @$internal
  @override
  $ProviderElement<SubmitMatchOpeners> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SubmitMatchOpeners create(Ref ref) {
    return submitMatchOpenersUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SubmitMatchOpeners value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SubmitMatchOpeners>(value),
    );
  }
}

String _$submitMatchOpenersUseCaseHash() =>
    r'6ff2026040b809beb55e83b0bb2faa77d5ca5e5c';

@ProviderFor(startMatchNowUseCase)
final startMatchNowUseCaseProvider = StartMatchNowUseCaseProvider._();

final class StartMatchNowUseCaseProvider
    extends $FunctionalProvider<StartMatchNow, StartMatchNow, StartMatchNow>
    with $Provider<StartMatchNow> {
  StartMatchNowUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'startMatchNowUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$startMatchNowUseCaseHash();

  @$internal
  @override
  $ProviderElement<StartMatchNow> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  StartMatchNow create(Ref ref) {
    return startMatchNowUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StartMatchNow value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StartMatchNow>(value),
    );
  }
}

String _$startMatchNowUseCaseHash() =>
    r'08ce4dbaed019770e4ab146f89369005c310a9af';

/// Live match-row updates (broadcast channel). Each subscription opens its
/// own channel; keep usage to one consumer per route (the Match Start
/// screen + the spectator scoreboard).

@ProviderFor(liveMatch)
final liveMatchProvider = LiveMatchFamily._();

/// Live match-row updates (broadcast channel). Each subscription opens its
/// own channel; keep usage to one consumer per route (the Match Start
/// screen + the spectator scoreboard).

final class LiveMatchProvider
    extends $FunctionalProvider<AsyncValue<Match?>, Match?, Stream<Match?>>
    with $FutureModifier<Match?>, $StreamProvider<Match?> {
  /// Live match-row updates (broadcast channel). Each subscription opens its
  /// own channel; keep usage to one consumer per route (the Match Start
  /// screen + the spectator scoreboard).
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

String _$liveMatchHash() => r'5de59b19f8b0fe4105cbf4b3b841a54a66140d23';

/// Live match-row updates (broadcast channel). Each subscription opens its
/// own channel; keep usage to one consumer per route (the Match Start
/// screen + the spectator scoreboard).

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

  LiveMatchProvider call(String matchId) =>
      LiveMatchProvider._(argument: matchId, from: this);

  @override
  String toString() => r'liveMatchProvider';
}

@ProviderFor(startInningsUseCase)
final startInningsUseCaseProvider = StartInningsUseCaseProvider._();

final class StartInningsUseCaseProvider
    extends $FunctionalProvider<StartInnings, StartInnings, StartInnings>
    with $Provider<StartInnings> {
  StartInningsUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'startInningsUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$startInningsUseCaseHash();

  @$internal
  @override
  $ProviderElement<StartInnings> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  StartInnings create(Ref ref) {
    return startInningsUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StartInnings value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StartInnings>(value),
    );
  }
}

String _$startInningsUseCaseHash() =>
    r'9e55f8541ddd311472dfead32fd860dad799df20';

@ProviderFor(recordBallUseCase)
final recordBallUseCaseProvider = RecordBallUseCaseProvider._();

final class RecordBallUseCaseProvider
    extends $FunctionalProvider<RecordBall, RecordBall, RecordBall>
    with $Provider<RecordBall> {
  RecordBallUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recordBallUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recordBallUseCaseHash();

  @$internal
  @override
  $ProviderElement<RecordBall> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RecordBall create(Ref ref) {
    return recordBallUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RecordBall value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RecordBall>(value),
    );
  }
}

String _$recordBallUseCaseHash() => r'73d6fd85f83b28806f878fc9f7f2ae26893992fe';

@ProviderFor(undoLastBallUseCase)
final undoLastBallUseCaseProvider = UndoLastBallUseCaseProvider._();

final class UndoLastBallUseCaseProvider
    extends $FunctionalProvider<UndoLastBall, UndoLastBall, UndoLastBall>
    with $Provider<UndoLastBall> {
  UndoLastBallUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'undoLastBallUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$undoLastBallUseCaseHash();

  @$internal
  @override
  $ProviderElement<UndoLastBall> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  UndoLastBall create(Ref ref) {
    return undoLastBallUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UndoLastBall value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UndoLastBall>(value),
    );
  }
}

String _$undoLastBallUseCaseHash() =>
    r'31d7abf195f64ca56fe7d5e67b53207ec3a16aa4';

@ProviderFor(watchBallsUseCase)
final watchBallsUseCaseProvider = WatchBallsUseCaseProvider._();

final class WatchBallsUseCaseProvider
    extends $FunctionalProvider<WatchBalls, WatchBalls, WatchBalls>
    with $Provider<WatchBalls> {
  WatchBallsUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'watchBallsUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$watchBallsUseCaseHash();

  @$internal
  @override
  $ProviderElement<WatchBalls> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  WatchBalls create(Ref ref) {
    return watchBallsUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WatchBalls value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WatchBalls>(value),
    );
  }
}

String _$watchBallsUseCaseHash() => r'6263ff4b65609b8a97b53d91ce389aa27afadf78';

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

String _$liveBallsHash() => r'4ed6db66dc7361f84962222137a72e50f808556a';

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

@ProviderFor(sendMatchChallengeUseCase)
final sendMatchChallengeUseCaseProvider = SendMatchChallengeUseCaseProvider._();

final class SendMatchChallengeUseCaseProvider
    extends
        $FunctionalProvider<
          SendMatchChallenge,
          SendMatchChallenge,
          SendMatchChallenge
        >
    with $Provider<SendMatchChallenge> {
  SendMatchChallengeUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sendMatchChallengeUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sendMatchChallengeUseCaseHash();

  @$internal
  @override
  $ProviderElement<SendMatchChallenge> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SendMatchChallenge create(Ref ref) {
    return sendMatchChallengeUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SendMatchChallenge value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SendMatchChallenge>(value),
    );
  }
}

String _$sendMatchChallengeUseCaseHash() =>
    r'158b5cfeabd5e7a72ab1fcefddbc2ec86b8e2b25';

@ProviderFor(acceptMatchChallengeUseCase)
final acceptMatchChallengeUseCaseProvider =
    AcceptMatchChallengeUseCaseProvider._();

final class AcceptMatchChallengeUseCaseProvider
    extends
        $FunctionalProvider<
          AcceptMatchChallenge,
          AcceptMatchChallenge,
          AcceptMatchChallenge
        >
    with $Provider<AcceptMatchChallenge> {
  AcceptMatchChallengeUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'acceptMatchChallengeUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$acceptMatchChallengeUseCaseHash();

  @$internal
  @override
  $ProviderElement<AcceptMatchChallenge> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AcceptMatchChallenge create(Ref ref) {
    return acceptMatchChallengeUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AcceptMatchChallenge value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AcceptMatchChallenge>(value),
    );
  }
}

String _$acceptMatchChallengeUseCaseHash() =>
    r'c2b4f180531790d83f3326b2f26a927eb4a23617';

@ProviderFor(counterMatchChallengeUseCase)
final counterMatchChallengeUseCaseProvider =
    CounterMatchChallengeUseCaseProvider._();

final class CounterMatchChallengeUseCaseProvider
    extends
        $FunctionalProvider<
          CounterMatchChallenge,
          CounterMatchChallenge,
          CounterMatchChallenge
        >
    with $Provider<CounterMatchChallenge> {
  CounterMatchChallengeUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'counterMatchChallengeUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$counterMatchChallengeUseCaseHash();

  @$internal
  @override
  $ProviderElement<CounterMatchChallenge> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CounterMatchChallenge create(Ref ref) {
    return counterMatchChallengeUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CounterMatchChallenge value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CounterMatchChallenge>(value),
    );
  }
}

String _$counterMatchChallengeUseCaseHash() =>
    r'9ea7a5aa5f4a0936a475210cec65d023563c04a2';

@ProviderFor(declineMatchChallengeUseCase)
final declineMatchChallengeUseCaseProvider =
    DeclineMatchChallengeUseCaseProvider._();

final class DeclineMatchChallengeUseCaseProvider
    extends
        $FunctionalProvider<
          DeclineMatchChallenge,
          DeclineMatchChallenge,
          DeclineMatchChallenge
        >
    with $Provider<DeclineMatchChallenge> {
  DeclineMatchChallengeUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'declineMatchChallengeUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$declineMatchChallengeUseCaseHash();

  @$internal
  @override
  $ProviderElement<DeclineMatchChallenge> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DeclineMatchChallenge create(Ref ref) {
    return declineMatchChallengeUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DeclineMatchChallenge value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DeclineMatchChallenge>(value),
    );
  }
}

String _$declineMatchChallengeUseCaseHash() =>
    r'441cdaf312bfe2800744bdb2d698506e05f5a772';

@ProviderFor(withdrawMatchChallengeUseCase)
final withdrawMatchChallengeUseCaseProvider =
    WithdrawMatchChallengeUseCaseProvider._();

final class WithdrawMatchChallengeUseCaseProvider
    extends
        $FunctionalProvider<
          WithdrawMatchChallenge,
          WithdrawMatchChallenge,
          WithdrawMatchChallenge
        >
    with $Provider<WithdrawMatchChallenge> {
  WithdrawMatchChallengeUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'withdrawMatchChallengeUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$withdrawMatchChallengeUseCaseHash();

  @$internal
  @override
  $ProviderElement<WithdrawMatchChallenge> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  WithdrawMatchChallenge create(Ref ref) {
    return withdrawMatchChallengeUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WithdrawMatchChallenge value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WithdrawMatchChallenge>(value),
    );
  }
}

String _$withdrawMatchChallengeUseCaseHash() =>
    r'42c448f04368128019c1f643bf8a1e0fd067636b';

@ProviderFor(getMatchChallengeUseCase)
final getMatchChallengeUseCaseProvider = GetMatchChallengeUseCaseProvider._();

final class GetMatchChallengeUseCaseProvider
    extends
        $FunctionalProvider<
          GetMatchChallenge,
          GetMatchChallenge,
          GetMatchChallenge
        >
    with $Provider<GetMatchChallenge> {
  GetMatchChallengeUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'getMatchChallengeUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$getMatchChallengeUseCaseHash();

  @$internal
  @override
  $ProviderElement<GetMatchChallenge> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GetMatchChallenge create(Ref ref) {
    return getMatchChallengeUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetMatchChallenge value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetMatchChallenge>(value),
    );
  }
}

String _$getMatchChallengeUseCaseHash() =>
    r'dbe1df804d7e64c081748c2eaf40e2ad3502fd7b';

@ProviderFor(listMyMatchChallengesUseCase)
final listMyMatchChallengesUseCaseProvider =
    ListMyMatchChallengesUseCaseProvider._();

final class ListMyMatchChallengesUseCaseProvider
    extends
        $FunctionalProvider<
          ListMyMatchChallenges,
          ListMyMatchChallenges,
          ListMyMatchChallenges
        >
    with $Provider<ListMyMatchChallenges> {
  ListMyMatchChallengesUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'listMyMatchChallengesUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$listMyMatchChallengesUseCaseHash();

  @$internal
  @override
  $ProviderElement<ListMyMatchChallenges> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ListMyMatchChallenges create(Ref ref) {
    return listMyMatchChallengesUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ListMyMatchChallenges value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ListMyMatchChallenges>(value),
    );
  }
}

String _$listMyMatchChallengesUseCaseHash() =>
    r'7113b1a37bdc1cedb762c49955aeaa25e95a62ca';

@ProviderFor(findMatchChallengeByCodeUseCase)
final findMatchChallengeByCodeUseCaseProvider =
    FindMatchChallengeByCodeUseCaseProvider._();

final class FindMatchChallengeByCodeUseCaseProvider
    extends
        $FunctionalProvider<
          FindMatchChallengeByCode,
          FindMatchChallengeByCode,
          FindMatchChallengeByCode
        >
    with $Provider<FindMatchChallengeByCode> {
  FindMatchChallengeByCodeUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'findMatchChallengeByCodeUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$findMatchChallengeByCodeUseCaseHash();

  @$internal
  @override
  $ProviderElement<FindMatchChallengeByCode> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FindMatchChallengeByCode create(Ref ref) {
    return findMatchChallengeByCodeUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FindMatchChallengeByCode value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FindMatchChallengeByCode>(value),
    );
  }
}

String _$findMatchChallengeByCodeUseCaseHash() =>
    r'b4b517e46c738251e29ef68df5a5b6592cd72737';

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

String _$myMatchChallengesHash() => r'b02cb0f6df156a47361bb84d1b27fd5cfa961401';

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

String _$matchChallengeHash() => r'7be0c6481138d81da8f828dd888dd69411375009';

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
