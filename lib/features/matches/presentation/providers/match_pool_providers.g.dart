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

String _$openMatchPoolHash() => r'cfd31a7ba3b920ffdad7e1a24777662347ad5de7';

/// Active match pool challenges hosted by user's own teams.

@ProviderFor(myPoolRequests)
final myPoolRequestsProvider = MyPoolRequestsProvider._();

/// Active match pool challenges hosted by user's own teams.

final class MyPoolRequestsProvider
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
  MyPoolRequestsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myPoolRequestsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myPoolRequestsHash();

  @$internal
  @override
  $FutureProviderElement<List<OpenMatchPoolItem>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<OpenMatchPoolItem>> create(Ref ref) {
    return myPoolRequests(ref);
  }
}

String _$myPoolRequestsHash() => r'6a7ec40ca21c1cfb81838b73c1f87acb1b391b85';

@ProviderFor(myChallenges)
final myChallengesProvider = MyChallengesProvider._();

final class MyChallengesProvider
    extends
        $FunctionalProvider<
          AsyncValue<MyChallengesView>,
          MyChallengesView,
          FutureOr<MyChallengesView>
        >
    with $FutureModifier<MyChallengesView>, $FutureProvider<MyChallengesView> {
  MyChallengesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myChallengesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myChallengesHash();

  @$internal
  @override
  $FutureProviderElement<MyChallengesView> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<MyChallengesView> create(Ref ref) {
    return myChallenges(ref);
  }
}

String _$myChallengesHash() => r'4faed2e4a6b790b2343545e6bc0ed47357e9ce71';

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

/// Selected facet on the Pool board.

@ProviderFor(OpenMatchPoolFilter)
final openMatchPoolFilterProvider = OpenMatchPoolFilterProvider._();

/// Selected facet on the Pool board.
final class OpenMatchPoolFilterProvider
    extends $NotifierProvider<OpenMatchPoolFilter, PoolFacet> {
  /// Selected facet on the Pool board.
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
  Override overrideWithValue(PoolFacet value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PoolFacet>(value),
    );
  }
}

String _$openMatchPoolFilterHash() =>
    r'a518321f10296e0ace86ad5945fae21362d050a4';

/// Selected facet on the Pool board.

abstract class _$OpenMatchPoolFilter extends $Notifier<PoolFacet> {
  PoolFacet build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<PoolFacet, PoolFacet>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PoolFacet, PoolFacet>,
              PoolFacet,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// The board's contents — open challenges narrowed by the selected facet.

@ProviderFor(filteredOpenMatchPool)
final filteredOpenMatchPoolProvider = FilteredOpenMatchPoolProvider._();

/// The board's contents — open challenges narrowed by the selected facet.

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
  /// The board's contents — open challenges narrowed by the selected facet.
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
    r'e7d5fa9a84bc6ae34de43b346953620c6a9dd7c8';

/// Whether the viewer manages a team, and so may post or apply.
///
/// False puts the board behind artboard 05's paper gate: still readable, but
/// no card is actionable. Membership alone is not enough — the design says
/// "only team managers can post challenges or apply to play".

@ProviderFor(viewerManagesTeam)
final viewerManagesTeamProvider = ViewerManagesTeamProvider._();

/// Whether the viewer manages a team, and so may post or apply.
///
/// False puts the board behind artboard 05's paper gate: still readable, but
/// no card is actionable. Membership alone is not enough — the design says
/// "only team managers can post challenges or apply to play".

final class ViewerManagesTeamProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Whether the viewer manages a team, and so may post or apply.
  ///
  /// False puts the board behind artboard 05's paper gate: still readable, but
  /// no card is actionable. Membership alone is not enough — the design says
  /// "only team managers can post challenges or apply to play".
  ViewerManagesTeamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'viewerManagesTeamProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$viewerManagesTeamHash();

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    return viewerManagesTeam(ref);
  }
}

String _$viewerManagesTeamHash() => r'00c7cc05b17c38e080b2ebb0e10e4509762a5082';
