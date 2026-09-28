// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'teams_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(teamsRepository)
final teamsRepositoryProvider = TeamsRepositoryProvider._();

final class TeamsRepositoryProvider
    extends
        $FunctionalProvider<TeamsRepository, TeamsRepository, TeamsRepository>
    with $Provider<TeamsRepository> {
  TeamsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'teamsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$teamsRepositoryHash();

  @$internal
  @override
  $ProviderElement<TeamsRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TeamsRepository create(Ref ref) {
    return teamsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TeamsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TeamsRepository>(value),
    );
  }
}

String _$teamsRepositoryHash() => r'ab9db3bdded7261464d685b4fe83a5b845fdb68e';

/// Scoped one-shot team profile read.

@ProviderFor(team)
final teamProvider = TeamFamily._();

/// Scoped one-shot team profile read.

final class TeamProvider
    extends $FunctionalProvider<AsyncValue<Team?>, Team?, FutureOr<Team?>>
    with $FutureModifier<Team?>, $FutureProvider<Team?> {
  /// Scoped one-shot team profile read.
  TeamProvider._({
    required TeamFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'teamProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$teamHash();

  @override
  String toString() {
    return r'teamProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Team?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Team?> create(Ref ref) {
    final argument = this.argument as String;
    return team(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TeamProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$teamHash() => r'9f2caeaaf0c3b438c2c0b479e7b651e186521ae6';

/// Scoped one-shot team profile read.

final class TeamFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Team?>, String> {
  TeamFamily._()
    : super(
        retry: null,
        name: r'teamProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Scoped one-shot team profile read.

  TeamProvider call(String teamId) =>
      TeamProvider._(argument: teamId, from: this);

  @override
  String toString() => r'teamProvider';
}

/// One-shot public/discoverable team list for selectors such as direct
/// challenges. This replaces the old permanent `allTeams` stream.

@ProviderFor(discoverableTeams)
final discoverableTeamsProvider = DiscoverableTeamsFamily._();

/// One-shot public/discoverable team list for selectors such as direct
/// challenges. This replaces the old permanent `allTeams` stream.

final class DiscoverableTeamsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Team>>,
          List<Team>,
          FutureOr<List<Team>>
        >
    with $FutureModifier<List<Team>>, $FutureProvider<List<Team>> {
  /// One-shot public/discoverable team list for selectors such as direct
  /// challenges. This replaces the old permanent `allTeams` stream.
  DiscoverableTeamsProvider._({
    required DiscoverableTeamsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'discoverableTeamsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$discoverableTeamsHash();

  @override
  String toString() {
    return r'discoverableTeamsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Team>> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<Team>> create(Ref ref) {
    final argument = this.argument as String;
    return discoverableTeams(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is DiscoverableTeamsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$discoverableTeamsHash() => r'6373626798b0733969f7c4fea2ff5860334276cc';

/// One-shot public/discoverable team list for selectors such as direct
/// challenges. This replaces the old permanent `allTeams` stream.

final class DiscoverableTeamsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Team>>, String> {
  DiscoverableTeamsFamily._()
    : super(
        retry: null,
        name: r'discoverableTeamsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// One-shot public/discoverable team list for selectors such as direct
  /// challenges. This replaces the old permanent `allTeams` stream.

  DiscoverableTeamsProvider call(String query) =>
      DiscoverableTeamsProvider._(argument: query, from: this);

  @override
  String toString() => r'discoverableTeamsProvider';
}
