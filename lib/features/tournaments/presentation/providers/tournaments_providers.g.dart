// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tournaments_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(tournamentsRepository)
final tournamentsRepositoryProvider = TournamentsRepositoryProvider._();

final class TournamentsRepositoryProvider
    extends
        $FunctionalProvider<
          TournamentsRepository,
          TournamentsRepository,
          TournamentsRepository
        >
    with $Provider<TournamentsRepository> {
  TournamentsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tournamentsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tournamentsRepositoryHash();

  @$internal
  @override
  $ProviderElement<TournamentsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TournamentsRepository create(Ref ref) {
    return tournamentsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TournamentsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TournamentsRepository>(value),
    );
  }
}

String _$tournamentsRepositoryHash() =>
    r'f03fa9197c89573aa39301f7ed8ebf622ddc23e0';

@ProviderFor(tournamentDetail)
final tournamentDetailProvider = TournamentDetailFamily._();

final class TournamentDetailProvider
    extends
        $FunctionalProvider<
          AsyncValue<Tournament>,
          Tournament,
          FutureOr<Tournament>
        >
    with $FutureModifier<Tournament>, $FutureProvider<Tournament> {
  TournamentDetailProvider._({
    required TournamentDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'tournamentDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$tournamentDetailHash();

  @override
  String toString() {
    return r'tournamentDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Tournament> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Tournament> create(Ref ref) {
    final argument = this.argument as String;
    return tournamentDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TournamentDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$tournamentDetailHash() => r'f423577518fe617c830e3a693d3fe41b29b25c40';

final class TournamentDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Tournament>, String> {
  TournamentDetailFamily._()
    : super(
        retry: null,
        name: r'tournamentDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TournamentDetailProvider call(String tournamentId) =>
      TournamentDetailProvider._(argument: tournamentId, from: this);

  @override
  String toString() => r'tournamentDetailProvider';
}

@ProviderFor(myTournaments)
final myTournamentsProvider = MyTournamentsProvider._();

final class MyTournamentsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Tournament>>,
          List<Tournament>,
          FutureOr<List<Tournament>>
        >
    with $FutureModifier<List<Tournament>>, $FutureProvider<List<Tournament>> {
  MyTournamentsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myTournamentsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myTournamentsHash();

  @$internal
  @override
  $FutureProviderElement<List<Tournament>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Tournament>> create(Ref ref) {
    return myTournaments(ref);
  }
}

String _$myTournamentsHash() => r'd79ab5bc96b9fb0cadf6f176873607f34a6074f0';

@ProviderFor(discoverTournaments)
final discoverTournamentsProvider = DiscoverTournamentsFamily._();

final class DiscoverTournamentsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Tournament>>,
          List<Tournament>,
          FutureOr<List<Tournament>>
        >
    with $FutureModifier<List<Tournament>>, $FutureProvider<List<Tournament>> {
  DiscoverTournamentsProvider._({
    required DiscoverTournamentsFamily super.from,
    required ({TournamentType? type, TournamentStatus? status, String? city})
    super.argument,
  }) : super(
         retry: null,
         name: r'discoverTournamentsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$discoverTournamentsHash();

  @override
  String toString() {
    return r'discoverTournamentsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<Tournament>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Tournament>> create(Ref ref) {
    final argument =
        this.argument
            as ({TournamentType? type, TournamentStatus? status, String? city});
    return discoverTournaments(
      ref,
      type: argument.type,
      status: argument.status,
      city: argument.city,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DiscoverTournamentsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$discoverTournamentsHash() =>
    r'6141d72aed8d74e156c5551c6ba59ea062ae4129';

final class DiscoverTournamentsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<Tournament>>,
          ({TournamentType? type, TournamentStatus? status, String? city})
        > {
  DiscoverTournamentsFamily._()
    : super(
        retry: null,
        name: r'discoverTournamentsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  DiscoverTournamentsProvider call({
    TournamentType? type,
    TournamentStatus? status,
    String? city,
  }) => DiscoverTournamentsProvider._(
    argument: (type: type, status: status, city: city),
    from: this,
  );

  @override
  String toString() => r'discoverTournamentsProvider';
}

@ProviderFor(tournamentRegistrations)
final tournamentRegistrationsProvider = TournamentRegistrationsFamily._();

final class TournamentRegistrationsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TournamentRegistration>>,
          List<TournamentRegistration>,
          FutureOr<List<TournamentRegistration>>
        >
    with
        $FutureModifier<List<TournamentRegistration>>,
        $FutureProvider<List<TournamentRegistration>> {
  TournamentRegistrationsProvider._({
    required TournamentRegistrationsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'tournamentRegistrationsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$tournamentRegistrationsHash();

  @override
  String toString() {
    return r'tournamentRegistrationsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<TournamentRegistration>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<TournamentRegistration>> create(Ref ref) {
    final argument = this.argument as String;
    return tournamentRegistrations(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TournamentRegistrationsProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$tournamentRegistrationsHash() =>
    r'e7d08cad132f4d3974a8b1160b53551b8527e0e5';

final class TournamentRegistrationsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<TournamentRegistration>>,
          String
        > {
  TournamentRegistrationsFamily._()
    : super(
        retry: null,
        name: r'tournamentRegistrationsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TournamentRegistrationsProvider call(String tournamentId) =>
      TournamentRegistrationsProvider._(argument: tournamentId, from: this);

  @override
  String toString() => r'tournamentRegistrationsProvider';
}

@ProviderFor(tournamentFixtures)
final tournamentFixturesProvider = TournamentFixturesFamily._();

final class TournamentFixturesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Match>>,
          List<Match>,
          FutureOr<List<Match>>
        >
    with $FutureModifier<List<Match>>, $FutureProvider<List<Match>> {
  TournamentFixturesProvider._({
    required TournamentFixturesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'tournamentFixturesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$tournamentFixturesHash();

  @override
  String toString() {
    return r'tournamentFixturesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Match>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Match>> create(Ref ref) {
    final argument = this.argument as String;
    return tournamentFixtures(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TournamentFixturesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$tournamentFixturesHash() =>
    r'6f4b970eb8f953c60df085f4f08c8a5e40ab607a';

final class TournamentFixturesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Match>>, String> {
  TournamentFixturesFamily._()
    : super(
        retry: null,
        name: r'tournamentFixturesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TournamentFixturesProvider call(String tournamentId) =>
      TournamentFixturesProvider._(argument: tournamentId, from: this);

  @override
  String toString() => r'tournamentFixturesProvider';
}

@ProviderFor(tournamentStandingsStream)
final tournamentStandingsStreamProvider = TournamentStandingsStreamFamily._();

final class TournamentStandingsStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TournamentStanding>>,
          List<TournamentStanding>,
          Stream<List<TournamentStanding>>
        >
    with
        $FutureModifier<List<TournamentStanding>>,
        $StreamProvider<List<TournamentStanding>> {
  TournamentStandingsStreamProvider._({
    required TournamentStandingsStreamFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'tournamentStandingsStreamProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$tournamentStandingsStreamHash();

  @override
  String toString() {
    return r'tournamentStandingsStreamProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<TournamentStanding>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<TournamentStanding>> create(Ref ref) {
    final argument = this.argument as String;
    return tournamentStandingsStream(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TournamentStandingsStreamProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$tournamentStandingsStreamHash() =>
    r'67af986f04ea5ae68cfd0febdaf143d187fe95d8';

final class TournamentStandingsStreamFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<TournamentStanding>>, String> {
  TournamentStandingsStreamFamily._()
    : super(
        retry: null,
        name: r'tournamentStandingsStreamProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TournamentStandingsStreamProvider call(String tournamentId) =>
      TournamentStandingsStreamProvider._(argument: tournamentId, from: this);

  @override
  String toString() => r'tournamentStandingsStreamProvider';
}

@ProviderFor(tournamentAwards)
final tournamentAwardsProvider = TournamentAwardsFamily._();

final class TournamentAwardsProvider
    extends
        $FunctionalProvider<
          AsyncValue<TournamentAwards>,
          TournamentAwards,
          FutureOr<TournamentAwards>
        >
    with $FutureModifier<TournamentAwards>, $FutureProvider<TournamentAwards> {
  TournamentAwardsProvider._({
    required TournamentAwardsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'tournamentAwardsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$tournamentAwardsHash();

  @override
  String toString() {
    return r'tournamentAwardsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<TournamentAwards> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<TournamentAwards> create(Ref ref) {
    final argument = this.argument as String;
    return tournamentAwards(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TournamentAwardsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$tournamentAwardsHash() => r'31a3638c43c64002399cea5e971c135fb6a77410';

final class TournamentAwardsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<TournamentAwards>, String> {
  TournamentAwardsFamily._()
    : super(
        retry: null,
        name: r'tournamentAwardsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TournamentAwardsProvider call(String tournamentId) =>
      TournamentAwardsProvider._(argument: tournamentId, from: this);

  @override
  String toString() => r'tournamentAwardsProvider';
}

/// The organiser's Live Ops board (artboard 27). Autodispose so leaving the
/// console drops the poll; the console re-arms it on the Live Ops tab.

@ProviderFor(tournamentLiveBoard)
final tournamentLiveBoardProvider = TournamentLiveBoardFamily._();

/// The organiser's Live Ops board (artboard 27). Autodispose so leaving the
/// console drops the poll; the console re-arms it on the Live Ops tab.

final class TournamentLiveBoardProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TournamentLiveMatch>>,
          List<TournamentLiveMatch>,
          FutureOr<List<TournamentLiveMatch>>
        >
    with
        $FutureModifier<List<TournamentLiveMatch>>,
        $FutureProvider<List<TournamentLiveMatch>> {
  /// The organiser's Live Ops board (artboard 27). Autodispose so leaving the
  /// console drops the poll; the console re-arms it on the Live Ops tab.
  TournamentLiveBoardProvider._({
    required TournamentLiveBoardFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'tournamentLiveBoardProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$tournamentLiveBoardHash();

  @override
  String toString() {
    return r'tournamentLiveBoardProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<TournamentLiveMatch>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<TournamentLiveMatch>> create(Ref ref) {
    final argument = this.argument as String;
    return tournamentLiveBoard(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TournamentLiveBoardProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$tournamentLiveBoardHash() =>
    r'920d613e06ee693a8ca98e5b332476fe6383d4ea';

/// The organiser's Live Ops board (artboard 27). Autodispose so leaving the
/// console drops the poll; the console re-arms it on the Live Ops tab.

final class TournamentLiveBoardFamily extends $Family
    with
        $FunctionalFamilyOverride<FutureOr<List<TournamentLiveMatch>>, String> {
  TournamentLiveBoardFamily._()
    : super(
        retry: null,
        name: r'tournamentLiveBoardProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The organiser's Live Ops board (artboard 27). Autodispose so leaving the
  /// console drops the poll; the console re-arms it on the Live Ops tab.

  TournamentLiveBoardProvider call(String tournamentId) =>
      TournamentLiveBoardProvider._(argument: tournamentId, from: this);

  @override
  String toString() => r'tournamentLiveBoardProvider';
}

/// The hub's "Playing" bucket: every registration belonging to a team the
/// user manages. Reads the teams feature through its presentation providers,
/// which is the sanctioned cross-feature seam.

@ProviderFor(myPlayingTournaments)
final myPlayingTournamentsProvider = MyPlayingTournamentsProvider._();

/// The hub's "Playing" bucket: every registration belonging to a team the
/// user manages. Reads the teams feature through its presentation providers,
/// which is the sanctioned cross-feature seam.

final class MyPlayingTournamentsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MyTournamentEntry>>,
          List<MyTournamentEntry>,
          FutureOr<List<MyTournamentEntry>>
        >
    with
        $FutureModifier<List<MyTournamentEntry>>,
        $FutureProvider<List<MyTournamentEntry>> {
  /// The hub's "Playing" bucket: every registration belonging to a team the
  /// user manages. Reads the teams feature through its presentation providers,
  /// which is the sanctioned cross-feature seam.
  MyPlayingTournamentsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myPlayingTournamentsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myPlayingTournamentsHash();

  @$internal
  @override
  $FutureProviderElement<List<MyTournamentEntry>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<MyTournamentEntry>> create(Ref ref) {
    return myPlayingTournaments(ref);
  }
}

String _$myPlayingTournamentsHash() =>
    r'68495ed248b72a65073d3fbbf835d83f7025c6a0';

/// Ground picker results. Autodispose and keyed by the query so typing does
/// not accumulate subscriptions.

@ProviderFor(groundSearch)
final groundSearchProvider = GroundSearchFamily._();

/// Ground picker results. Autodispose and keyed by the query so typing does
/// not accumulate subscriptions.

final class GroundSearchProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Ground>>,
          List<Ground>,
          FutureOr<List<Ground>>
        >
    with $FutureModifier<List<Ground>>, $FutureProvider<List<Ground>> {
  /// Ground picker results. Autodispose and keyed by the query so typing does
  /// not accumulate subscriptions.
  GroundSearchProvider._({
    required GroundSearchFamily super.from,
    required ({String? query, double? latitude, double? longitude})
    super.argument,
  }) : super(
         retry: null,
         name: r'groundSearchProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$groundSearchHash();

  @override
  String toString() {
    return r'groundSearchProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<Ground>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Ground>> create(Ref ref) {
    final argument =
        this.argument as ({String? query, double? latitude, double? longitude});
    return groundSearch(
      ref,
      query: argument.query,
      latitude: argument.latitude,
      longitude: argument.longitude,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is GroundSearchProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$groundSearchHash() => r'29905f718d3ed5543ad3818c16e5416ae935332a';

/// Ground picker results. Autodispose and keyed by the query so typing does
/// not accumulate subscriptions.

final class GroundSearchFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<Ground>>,
          ({String? query, double? latitude, double? longitude})
        > {
  GroundSearchFamily._()
    : super(
        retry: null,
        name: r'groundSearchProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Ground picker results. Autodispose and keyed by the query so typing does
  /// not accumulate subscriptions.

  GroundSearchProvider call({
    String? query,
    double? latitude,
    double? longitude,
  }) => GroundSearchProvider._(
    argument: (query: query, latitude: latitude, longitude: longitude),
    from: this,
  );

  @override
  String toString() => r'groundSearchProvider';
}

/// The grounds a tournament actually uses, in display order.

@ProviderFor(tournamentGrounds)
final tournamentGroundsProvider = TournamentGroundsFamily._();

/// The grounds a tournament actually uses, in display order.

final class TournamentGroundsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Ground>>,
          List<Ground>,
          FutureOr<List<Ground>>
        >
    with $FutureModifier<List<Ground>>, $FutureProvider<List<Ground>> {
  /// The grounds a tournament actually uses, in display order.
  TournamentGroundsProvider._({
    required TournamentGroundsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'tournamentGroundsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$tournamentGroundsHash();

  @override
  String toString() {
    return r'tournamentGroundsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Ground>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Ground>> create(Ref ref) {
    final argument = this.argument as String;
    return tournamentGrounds(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TournamentGroundsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$tournamentGroundsHash() => r'0b6bc7492b84df9eb69fd3389e558d8805890b65';

/// The grounds a tournament actually uses, in display order.

final class TournamentGroundsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Ground>>, String> {
  TournamentGroundsFamily._()
    : super(
        retry: null,
        name: r'tournamentGroundsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The grounds a tournament actually uses, in display order.

  TournamentGroundsProvider call(String tournamentId) =>
      TournamentGroundsProvider._(argument: tournamentId, from: this);

  @override
  String toString() => r'tournamentGroundsProvider';
}

/// Who the organiser can appoint to score a fixture.

@ProviderFor(tournamentScorerCandidates)
final tournamentScorerCandidatesProvider = TournamentScorerCandidatesFamily._();

/// Who the organiser can appoint to score a fixture.

final class TournamentScorerCandidatesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ScorerCandidate>>,
          List<ScorerCandidate>,
          FutureOr<List<ScorerCandidate>>
        >
    with
        $FutureModifier<List<ScorerCandidate>>,
        $FutureProvider<List<ScorerCandidate>> {
  /// Who the organiser can appoint to score a fixture.
  TournamentScorerCandidatesProvider._({
    required TournamentScorerCandidatesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'tournamentScorerCandidatesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$tournamentScorerCandidatesHash();

  @override
  String toString() {
    return r'tournamentScorerCandidatesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<ScorerCandidate>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ScorerCandidate>> create(Ref ref) {
    final argument = this.argument as String;
    return tournamentScorerCandidates(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TournamentScorerCandidatesProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$tournamentScorerCandidatesHash() =>
    r'3973746c5fe4f4609f40eb2b2aa8700c2c7a25ee';

/// Who the organiser can appoint to score a fixture.

final class TournamentScorerCandidatesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<ScorerCandidate>>, String> {
  TournamentScorerCandidatesFamily._()
    : super(
        retry: null,
        name: r'tournamentScorerCandidatesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Who the organiser can appoint to score a fixture.

  TournamentScorerCandidatesProvider call(String tournamentId) =>
      TournamentScorerCandidatesProvider._(argument: tournamentId, from: this);

  @override
  String toString() => r'tournamentScorerCandidatesProvider';
}

@ProviderFor(tournamentDraftStream)
final tournamentDraftStreamProvider = TournamentDraftStreamProvider._();

final class TournamentDraftStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, dynamic>?>,
          Map<String, dynamic>?,
          Stream<Map<String, dynamic>?>
        >
    with
        $FutureModifier<Map<String, dynamic>?>,
        $StreamProvider<Map<String, dynamic>?> {
  TournamentDraftStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tournamentDraftStreamProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tournamentDraftStreamHash();

  @$internal
  @override
  $StreamProviderElement<Map<String, dynamic>?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Map<String, dynamic>?> create(Ref ref) {
    return tournamentDraftStream(ref);
  }
}

String _$tournamentDraftStreamHash() =>
    r'a124c7f6de5c134d6af02d9dc8706f09799023fe';
