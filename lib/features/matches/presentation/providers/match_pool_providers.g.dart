// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_pool_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(matchPoolRepository)
final matchPoolRepositoryProvider = MatchPoolRepositoryProvider._();

final class MatchPoolRepositoryProvider
    extends
        $FunctionalProvider<
          MatchPoolRepository,
          MatchPoolRepository,
          MatchPoolRepository
        >
    with $Provider<MatchPoolRepository> {
  MatchPoolRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'matchPoolRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$matchPoolRepositoryHash();

  @$internal
  @override
  $ProviderElement<MatchPoolRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MatchPoolRepository create(Ref ref) {
    return matchPoolRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MatchPoolRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MatchPoolRepository>(value),
    );
  }
}

String _$matchPoolRepositoryHash() =>
    r'9e2bf8a4971f368d59fa297b33eafb6901ac8e76';

/// Open match pool challenges from other teams, mapped with team metadata.

@ProviderFor(openMatchPool)
final openMatchPoolProvider = OpenMatchPoolProvider._();

/// Open match pool challenges from other teams, mapped with team metadata.

final class OpenMatchPoolProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<OpenMatchPoolItem>>,
          List<OpenMatchPoolItem>,
          FutureOr<List<OpenMatchPoolItem>>
        >
    with
        $FutureModifier<List<OpenMatchPoolItem>>,
        $FutureProvider<List<OpenMatchPoolItem>> {
  /// Open match pool challenges from other teams, mapped with team metadata.
  OpenMatchPoolProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'openMatchPoolProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$openMatchPoolHash();

  @$internal
  @override
  $FutureProviderElement<List<OpenMatchPoolItem>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<OpenMatchPoolItem>> create(Ref ref) {
    return openMatchPool(ref);
  }
}

String _$openMatchPoolHash() => r'79d2c4c0f7f819e5e4d122d81d901c4a14a39caa';

/// Active match pool challenges hosted by user's own teams.

@ProviderFor(myPoolBroadcasts)
final myPoolBroadcastsProvider = MyPoolBroadcastsProvider._();

/// Active match pool challenges hosted by user's own teams.

final class MyPoolBroadcastsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<OpenMatchPoolItem>>,
          List<OpenMatchPoolItem>,
          FutureOr<List<OpenMatchPoolItem>>
        >
    with
        $FutureModifier<List<OpenMatchPoolItem>>,
        $FutureProvider<List<OpenMatchPoolItem>> {
  /// Active match pool challenges hosted by user's own teams.
  MyPoolBroadcastsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myPoolBroadcastsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myPoolBroadcastsHash();

  @$internal
  @override
  $FutureProviderElement<List<OpenMatchPoolItem>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<OpenMatchPoolItem>> create(Ref ref) {
    return myPoolBroadcasts(ref);
  }
}

String _$myPoolBroadcastsHash() => r'fd0f7a4377678bc172482ffec21f8c18bcc60efb';

/// Applications for a specific match pool challenge.

@ProviderFor(challengePoolApplications)
final challengePoolApplicationsProvider = ChallengePoolApplicationsFamily._();

/// Applications for a specific match pool challenge.

final class ChallengePoolApplicationsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MatchPoolApplication>>,
          List<MatchPoolApplication>,
          FutureOr<List<MatchPoolApplication>>
        >
    with
        $FutureModifier<List<MatchPoolApplication>>,
        $FutureProvider<List<MatchPoolApplication>> {
  /// Applications for a specific match pool challenge.
  ChallengePoolApplicationsProvider._({
    required ChallengePoolApplicationsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'challengePoolApplicationsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$challengePoolApplicationsHash();

  @override
  String toString() {
    return r'challengePoolApplicationsProvider'
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
    return challengePoolApplications(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ChallengePoolApplicationsProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$challengePoolApplicationsHash() =>
    r'c949321be0c477f40b31bc3a5202655f518fe185';

/// Applications for a specific match pool challenge.

final class ChallengePoolApplicationsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<MatchPoolApplication>>,
          String
        > {
  ChallengePoolApplicationsFamily._()
    : super(
        retry: null,
        name: r'challengePoolApplicationsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Applications for a specific match pool challenge.

  ChallengePoolApplicationsProvider call(String requestId) =>
      ChallengePoolApplicationsProvider._(argument: requestId, from: this);

  @override
  String toString() => r'challengePoolApplicationsProvider';
}

/// Selected format filter for the Open Match Pool screen.

@ProviderFor(OpenMatchPoolFilter)
final openMatchPoolFilterProvider = OpenMatchPoolFilterProvider._();

/// Selected format filter for the Open Match Pool screen.
final class OpenMatchPoolFilterProvider
    extends $NotifierProvider<OpenMatchPoolFilter, String> {
  /// Selected format filter for the Open Match Pool screen.
  OpenMatchPoolFilterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'openMatchPoolFilterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$openMatchPoolFilterHash();

  @$internal
  @override
  OpenMatchPoolFilter create() => OpenMatchPoolFilter();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$openMatchPoolFilterHash() =>
    r'bf3d1d4df3149a96145f5ccd61e00ec89728f468';

/// Selected format filter for the Open Match Pool screen.

abstract class _$OpenMatchPoolFilter extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Filtered open match pool items strictly derived from domain & filter state.

@ProviderFor(filteredOpenMatchPool)
final filteredOpenMatchPoolProvider = FilteredOpenMatchPoolProvider._();

/// Filtered open match pool items strictly derived from domain & filter state.

final class FilteredOpenMatchPoolProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<OpenMatchPoolItem>>,
          List<OpenMatchPoolItem>,
          FutureOr<List<OpenMatchPoolItem>>
        >
    with
        $FutureModifier<List<OpenMatchPoolItem>>,
        $FutureProvider<List<OpenMatchPoolItem>> {
  /// Filtered open match pool items strictly derived from domain & filter state.
  FilteredOpenMatchPoolProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'filteredOpenMatchPoolProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$filteredOpenMatchPoolHash();

  @$internal
  @override
  $FutureProviderElement<List<OpenMatchPoolItem>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<OpenMatchPoolItem>> create(Ref ref) {
    return filteredOpenMatchPool(ref);
  }
}

String _$filteredOpenMatchPoolHash() =>
    r'0bd992aa11dc80f5c2a5abbf9a089677e09a486c';
