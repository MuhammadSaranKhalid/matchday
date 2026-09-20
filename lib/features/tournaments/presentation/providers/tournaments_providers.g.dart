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
    r'82016014e3f0dc76ace03eb4cf75d23852cb6df5';

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
    r'cf478186000379d9b0bd70ef963f66a73f77235e';

/// The fee ledger for one cup (artboard 24c). Organiser-only on the server,
/// so a manager who reaches the route gets an error rather than an empty list.

@ProviderFor(tournamentFeeLedger)
final tournamentFeeLedgerProvider = TournamentFeeLedgerFamily._();

/// The fee ledger for one cup (artboard 24c). Organiser-only on the server,
/// so a manager who reaches the route gets an error rather than an empty list.

final class TournamentFeeLedgerProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TournamentFeeEntry>>,
          List<TournamentFeeEntry>,
          FutureOr<List<TournamentFeeEntry>>
        >
    with
        $FutureModifier<List<TournamentFeeEntry>>,
        $FutureProvider<List<TournamentFeeEntry>> {
  /// The fee ledger for one cup (artboard 24c). Organiser-only on the server,
  /// so a manager who reaches the route gets an error rather than an empty list.
  TournamentFeeLedgerProvider._({
    required TournamentFeeLedgerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'tournamentFeeLedgerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$tournamentFeeLedgerHash();

  @override
  String toString() {
    return r'tournamentFeeLedgerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<TournamentFeeEntry>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<TournamentFeeEntry>> create(Ref ref) {
    final argument = this.argument as String;
    return tournamentFeeLedger(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TournamentFeeLedgerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$tournamentFeeLedgerHash() =>
    r'6872653ee2c4e6b291b1a7855a1d64b485acd80c';

/// The fee ledger for one cup (artboard 24c). Organiser-only on the server,
/// so a manager who reaches the route gets an error rather than an empty list.

final class TournamentFeeLedgerFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<TournamentFeeEntry>>, String> {
  TournamentFeeLedgerFamily._()
    : super(
        retry: null,
        name: r'tournamentFeeLedgerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The fee ledger for one cup (artboard 24c). Organiser-only on the server,
  /// so a manager who reaches the route gets an error rather than an empty list.

  TournamentFeeLedgerProvider call(String tournamentId) =>
      TournamentFeeLedgerProvider._(argument: tournamentId, from: this);

  @override
  String toString() => r'tournamentFeeLedgerProvider';
}

/// Everyone already appointed to one fixture (artboard 27j).

@ProviderFor(matchOfficials)
final matchOfficialsProvider = MatchOfficialsFamily._();

/// Everyone already appointed to one fixture (artboard 27j).

final class MatchOfficialsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MatchOfficial>>,
          List<MatchOfficial>,
          FutureOr<List<MatchOfficial>>
        >
    with
        $FutureModifier<List<MatchOfficial>>,
        $FutureProvider<List<MatchOfficial>> {
  /// Everyone already appointed to one fixture (artboard 27j).
  MatchOfficialsProvider._({
    required MatchOfficialsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'matchOfficialsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$matchOfficialsHash();

  @override
  String toString() {
    return r'matchOfficialsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<MatchOfficial>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<MatchOfficial>> create(Ref ref) {
    final argument = this.argument as String;
    return matchOfficials(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MatchOfficialsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$matchOfficialsHash() => r'8c4934c9189bb27e394ffdba72e92bf0af04479b';

/// Everyone already appointed to one fixture (artboard 27j).

final class MatchOfficialsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<MatchOfficial>>, String> {
  MatchOfficialsFamily._()
    : super(
        retry: null,
        name: r'matchOfficialsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Everyone already appointed to one fixture (artboard 27j).

  MatchOfficialsProvider call(String matchId) =>
      MatchOfficialsProvider._(argument: matchId, from: this);

  @override
  String toString() => r'matchOfficialsProvider';
}

/// Everyone who *could* be appointed to one fixture (artboard 27j).

@ProviderFor(officialCandidates)
final officialCandidatesProvider = OfficialCandidatesFamily._();

/// Everyone who *could* be appointed to one fixture (artboard 27j).

final class OfficialCandidatesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<OfficialCandidate>>,
          List<OfficialCandidate>,
          FutureOr<List<OfficialCandidate>>
        >
    with
        $FutureModifier<List<OfficialCandidate>>,
        $FutureProvider<List<OfficialCandidate>> {
  /// Everyone who *could* be appointed to one fixture (artboard 27j).
  OfficialCandidatesProvider._({
    required OfficialCandidatesFamily super.from,
    required ({String tournamentId, String matchId}) super.argument,
  }) : super(
         retry: null,
         name: r'officialCandidatesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$officialCandidatesHash();

  @override
  String toString() {
    return r'officialCandidatesProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<OfficialCandidate>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<OfficialCandidate>> create(Ref ref) {
    final argument = this.argument as ({String tournamentId, String matchId});
    return officialCandidates(
      ref,
      tournamentId: argument.tournamentId,
      matchId: argument.matchId,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is OfficialCandidatesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$officialCandidatesHash() =>
    r'2c46490ceecaad1df7e0f757b11e394f02dde9eb';

/// Everyone who *could* be appointed to one fixture (artboard 27j).

final class OfficialCandidatesFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<OfficialCandidate>>,
          ({String tournamentId, String matchId})
        > {
  OfficialCandidatesFamily._()
    : super(
        retry: null,
        name: r'officialCandidatesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Everyone who *could* be appointed to one fixture (artboard 27j).

  OfficialCandidatesProvider call({
    required String tournamentId,
    required String matchId,
  }) => OfficialCandidatesProvider._(
    argument: (tournamentId: tournamentId, matchId: matchId),
    from: this,
  );

  @override
  String toString() => r'officialCandidatesProvider';
}

/// The cup's orange- and purple-cap boards (artboards 10, 11, 15).

@ProviderFor(tournamentLeaderboards)
final tournamentLeaderboardsProvider = TournamentLeaderboardsFamily._();

/// The cup's orange- and purple-cap boards (artboards 10, 11, 15).

final class TournamentLeaderboardsProvider
    extends
        $FunctionalProvider<
          AsyncValue<TournamentLeaderboards>,
          TournamentLeaderboards,
          FutureOr<TournamentLeaderboards>
        >
    with
        $FutureModifier<TournamentLeaderboards>,
        $FutureProvider<TournamentLeaderboards> {
  /// The cup's orange- and purple-cap boards (artboards 10, 11, 15).
  TournamentLeaderboardsProvider._({
    required TournamentLeaderboardsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'tournamentLeaderboardsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$tournamentLeaderboardsHash();

  @override
  String toString() {
    return r'tournamentLeaderboardsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<TournamentLeaderboards> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<TournamentLeaderboards> create(Ref ref) {
    final argument = this.argument as String;
    return tournamentLeaderboards(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TournamentLeaderboardsProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$tournamentLeaderboardsHash() =>
    r'de2122c0363f0c4bbdce63facf12e0c9c58b99ba';

/// The cup's orange- and purple-cap boards (artboards 10, 11, 15).

final class TournamentLeaderboardsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<TournamentLeaderboards>, String> {
  TournamentLeaderboardsFamily._()
    : super(
        retry: null,
        name: r'tournamentLeaderboardsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The cup's orange- and purple-cap boards (artboards 10, 11, 15).

  TournamentLeaderboardsProvider call(String tournamentId) =>
      TournamentLeaderboardsProvider._(argument: tournamentId, from: this);

  @override
  String toString() => r'tournamentLeaderboardsProvider';
}

/// The organiser's track record (artboard 09).

@ProviderFor(tournamentOrganizer)
final tournamentOrganizerProvider = TournamentOrganizerFamily._();

/// The organiser's track record (artboard 09).

final class TournamentOrganizerProvider
    extends
        $FunctionalProvider<
          AsyncValue<TournamentOrganizer?>,
          TournamentOrganizer?,
          FutureOr<TournamentOrganizer?>
        >
    with
        $FutureModifier<TournamentOrganizer?>,
        $FutureProvider<TournamentOrganizer?> {
  /// The organiser's track record (artboard 09).
  TournamentOrganizerProvider._({
    required TournamentOrganizerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'tournamentOrganizerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$tournamentOrganizerHash();

  @override
  String toString() {
    return r'tournamentOrganizerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<TournamentOrganizer?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<TournamentOrganizer?> create(Ref ref) {
    final argument = this.argument as String;
    return tournamentOrganizer(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TournamentOrganizerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$tournamentOrganizerHash() =>
    r'53ca953ec13bb9d5eb9b635a1e52a923155e04b5';

/// The organiser's track record (artboard 09).

final class TournamentOrganizerFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<TournamentOrganizer?>, String> {
  TournamentOrganizerFamily._()
    : super(
        retry: null,
        name: r'tournamentOrganizerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The organiser's track record (artboard 09).

  TournamentOrganizerProvider call(String tournamentId) =>
      TournamentOrganizerProvider._(argument: tournamentId, from: this);

  @override
  String toString() => r'tournamentOrganizerProvider';
}
