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

String _$matchHash() => r'dd4bb3dee447b5c077c1196304adf2acc1625a7c';

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

String _$myMatchesHash() => r'62c725f1cc00e35b3750e7c2ae0ee640cac868f2';
