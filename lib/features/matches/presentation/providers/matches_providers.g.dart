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

@ProviderFor(createMatchRequestUseCase)
final createMatchRequestUseCaseProvider = CreateMatchRequestUseCaseProvider._();

final class CreateMatchRequestUseCaseProvider
    extends
        $FunctionalProvider<
          CreateMatchRequest,
          CreateMatchRequest,
          CreateMatchRequest
        >
    with $Provider<CreateMatchRequest> {
  CreateMatchRequestUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'createMatchRequestUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$createMatchRequestUseCaseHash();

  @$internal
  @override
  $ProviderElement<CreateMatchRequest> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CreateMatchRequest create(Ref ref) {
    return createMatchRequestUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CreateMatchRequest value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CreateMatchRequest>(value),
    );
  }
}

String _$createMatchRequestUseCaseHash() =>
    r'60f0edbd25861b30eaa7e7993bd3119cdfbaf3f0';

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

@ProviderFor(getCurrentInningsUseCase)
final getCurrentInningsUseCaseProvider = GetCurrentInningsUseCaseProvider._();

final class GetCurrentInningsUseCaseProvider
    extends
        $FunctionalProvider<
          GetCurrentInnings,
          GetCurrentInnings,
          GetCurrentInnings
        >
    with $Provider<GetCurrentInnings> {
  GetCurrentInningsUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'getCurrentInningsUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$getCurrentInningsUseCaseHash();

  @$internal
  @override
  $ProviderElement<GetCurrentInnings> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GetCurrentInnings create(Ref ref) {
    return getCurrentInningsUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetCurrentInnings value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetCurrentInnings>(value),
    );
  }
}

String _$getCurrentInningsUseCaseHash() =>
    r'9e65d57e4a03ea63c5849203bc467680315b0770';

/// The latest innings for a match (one-shot; the spectator then streams it).

@ProviderFor(currentInnings)
final currentInningsProvider = CurrentInningsFamily._();

/// The latest innings for a match (one-shot; the spectator then streams it).

final class CurrentInningsProvider
    extends
        $FunctionalProvider<AsyncValue<Innings?>, Innings?, FutureOr<Innings?>>
    with $FutureModifier<Innings?>, $FutureProvider<Innings?> {
  /// The latest innings for a match (one-shot; the spectator then streams it).
  CurrentInningsProvider._({
    required CurrentInningsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'currentInningsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$currentInningsHash();

  @override
  String toString() {
    return r'currentInningsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Innings?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Innings?> create(Ref ref) {
    final argument = this.argument as String;
    return currentInnings(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CurrentInningsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$currentInningsHash() => r'970d19a9fcde0ba65e99873a0bef276390cd25a1';

/// The latest innings for a match (one-shot; the spectator then streams it).

final class CurrentInningsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Innings?>, String> {
  CurrentInningsFamily._()
    : super(
        retry: null,
        name: r'currentInningsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The latest innings for a match (one-shot; the spectator then streams it).

  CurrentInningsProvider call(String matchId) =>
      CurrentInningsProvider._(argument: matchId, from: this);

  @override
  String toString() => r'currentInningsProvider';
}

@ProviderFor(acceptMatchUseCase)
final acceptMatchUseCaseProvider = AcceptMatchUseCaseProvider._();

final class AcceptMatchUseCaseProvider
    extends $FunctionalProvider<AcceptMatch, AcceptMatch, AcceptMatch>
    with $Provider<AcceptMatch> {
  AcceptMatchUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'acceptMatchUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$acceptMatchUseCaseHash();

  @$internal
  @override
  $ProviderElement<AcceptMatch> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AcceptMatch create(Ref ref) {
    return acceptMatchUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AcceptMatch value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AcceptMatch>(value),
    );
  }
}

String _$acceptMatchUseCaseHash() =>
    r'59c2bde4973deaaf96c1e82e3be33f3b8849f4b2';

@ProviderFor(declineMatchUseCase)
final declineMatchUseCaseProvider = DeclineMatchUseCaseProvider._();

final class DeclineMatchUseCaseProvider
    extends $FunctionalProvider<DeclineMatch, DeclineMatch, DeclineMatch>
    with $Provider<DeclineMatch> {
  DeclineMatchUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'declineMatchUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$declineMatchUseCaseHash();

  @$internal
  @override
  $ProviderElement<DeclineMatch> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DeclineMatch create(Ref ref) {
    return declineMatchUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DeclineMatch value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DeclineMatch>(value),
    );
  }
}

String _$declineMatchUseCaseHash() =>
    r'b507ad729db85ad6ccbaa26b59edb69a81604661';

@ProviderFor(startMatchUseCase)
final startMatchUseCaseProvider = StartMatchUseCaseProvider._();

final class StartMatchUseCaseProvider
    extends $FunctionalProvider<StartMatch, StartMatch, StartMatch>
    with $Provider<StartMatch> {
  StartMatchUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'startMatchUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$startMatchUseCaseHash();

  @$internal
  @override
  $ProviderElement<StartMatch> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  StartMatch create(Ref ref) {
    return startMatchUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StartMatch value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StartMatch>(value),
    );
  }
}

String _$startMatchUseCaseHash() => r'81d86d4c53aeea67f0d7f0af6b216eb1876bd1f9';

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

@ProviderFor(watchInningsUseCase)
final watchInningsUseCaseProvider = WatchInningsUseCaseProvider._();

final class WatchInningsUseCaseProvider
    extends $FunctionalProvider<WatchInnings, WatchInnings, WatchInnings>
    with $Provider<WatchInnings> {
  WatchInningsUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'watchInningsUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$watchInningsUseCaseHash();

  @$internal
  @override
  $ProviderElement<WatchInnings> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  WatchInnings create(Ref ref) {
    return watchInningsUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WatchInnings value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WatchInnings>(value),
    );
  }
}

String _$watchInningsUseCaseHash() =>
    r'3b175efd33c786cafb4e81b5103fed65bc33268c';

/// Live deliveries for an innings (realtime).

@ProviderFor(balls)
final ballsProvider = BallsFamily._();

/// Live deliveries for an innings (realtime).

final class BallsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Ball>>,
          List<Ball>,
          Stream<List<Ball>>
        >
    with $FutureModifier<List<Ball>>, $StreamProvider<List<Ball>> {
  /// Live deliveries for an innings (realtime).
  BallsProvider._({
    required BallsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'ballsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$ballsHash();

  @override
  String toString() {
    return r'ballsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<Ball>> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<Ball>> create(Ref ref) {
    final argument = this.argument as String;
    return balls(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is BallsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$ballsHash() => r'4cd5a20eed9811614a30bae0cbb7fb161f592315';

/// Live deliveries for an innings (realtime).

final class BallsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<Ball>>, String> {
  BallsFamily._()
    : super(
        retry: null,
        name: r'ballsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Live deliveries for an innings (realtime).

  BallsProvider call(String inningsId) =>
      BallsProvider._(argument: inningsId, from: this);

  @override
  String toString() => r'ballsProvider';
}

/// Live innings state (realtime).

@ProviderFor(liveInnings)
final liveInningsProvider = LiveInningsFamily._();

/// Live innings state (realtime).

final class LiveInningsProvider
    extends
        $FunctionalProvider<AsyncValue<Innings?>, Innings?, Stream<Innings?>>
    with $FutureModifier<Innings?>, $StreamProvider<Innings?> {
  /// Live innings state (realtime).
  LiveInningsProvider._({
    required LiveInningsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'liveInningsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$liveInningsHash();

  @override
  String toString() {
    return r'liveInningsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<Innings?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<Innings?> create(Ref ref) {
    final argument = this.argument as String;
    return liveInnings(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is LiveInningsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$liveInningsHash() => r'16e2240ecfb62a8ecf55cc30a4afd2d8bf8b3bbe';

/// Live innings state (realtime).

final class LiveInningsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<Innings?>, String> {
  LiveInningsFamily._()
    : super(
        retry: null,
        name: r'liveInningsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Live innings state (realtime).

  LiveInningsProvider call(String inningsId) =>
      LiveInningsProvider._(argument: inningsId, from: this);

  @override
  String toString() => r'liveInningsProvider';
}

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
