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

/// Teams owned/managed by the signed-in user. Empty when signed out.

@ProviderFor(myTeams)
final myTeamsProvider = MyTeamsProvider._();

/// Teams owned/managed by the signed-in user. Empty when signed out.

final class MyTeamsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Team>>,
          List<Team>,
          Stream<List<Team>>
        >
    with $FutureModifier<List<Team>>, $StreamProvider<List<Team>> {
  /// Teams owned/managed by the signed-in user. Empty when signed out.
  MyTeamsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myTeamsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myTeamsHash();

  @$internal
  @override
  $StreamProviderElement<List<Team>> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<Team>> create(Ref ref) {
    return myTeams(ref);
  }
}

String _$myTeamsHash() => r'b6fa6cd165a14cd79370c0dcf8cc1493ca619114';

/// All teams visible to the signed-in user (used by match setup's opponent
/// picker).

@ProviderFor(allTeams)
final allTeamsProvider = AllTeamsProvider._();

/// All teams visible to the signed-in user (used by match setup's opponent
/// picker).

final class AllTeamsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Team>>,
          List<Team>,
          Stream<List<Team>>
        >
    with $FutureModifier<List<Team>>, $StreamProvider<List<Team>> {
  /// All teams visible to the signed-in user (used by match setup's opponent
  /// picker).
  AllTeamsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'allTeamsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$allTeamsHash();

  @$internal
  @override
  $StreamProviderElement<List<Team>> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<Team>> create(Ref ref) {
    return allTeams(ref);
  }
}

String _$allTeamsHash() => r'a6c39fd0272afa8b23bedc2e4bad849f752bba52';

/// A single team (hub view). Null if not found / not accessible.

@ProviderFor(team)
final teamProvider = TeamFamily._();

/// A single team (hub view). Null if not found / not accessible.

final class TeamProvider
    extends $FunctionalProvider<AsyncValue<Team?>, Team?, Stream<Team?>>
    with $FutureModifier<Team?>, $StreamProvider<Team?> {
  /// A single team (hub view). Null if not found / not accessible.
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
  $StreamProviderElement<Team?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<Team?> create(Ref ref) {
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

String _$teamHash() => r'c34145eadbada5954c0db00d1f32259f6d60e1b8';

/// A single team (hub view). Null if not found / not accessible.

final class TeamFamily extends $Family
    with $FunctionalFamilyOverride<Stream<Team?>, String> {
  TeamFamily._()
    : super(
        retry: null,
        name: r'teamProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// A single team (hub view). Null if not found / not accessible.

  TeamProvider call(String teamId) =>
      TeamProvider._(argument: teamId, from: this);

  @override
  String toString() => r'teamProvider';
}

/// A team's roster (members + display names).

@ProviderFor(roster)
final rosterProvider = RosterFamily._();

/// A team's roster (members + display names).

final class RosterProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<RosterMember>>,
          List<RosterMember>,
          Stream<List<RosterMember>>
        >
    with
        $FutureModifier<List<RosterMember>>,
        $StreamProvider<List<RosterMember>> {
  /// A team's roster (members + display names).
  RosterProvider._({
    required RosterFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'rosterProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$rosterHash();

  @override
  String toString() {
    return r'rosterProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<RosterMember>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<RosterMember>> create(Ref ref) {
    final argument = this.argument as String;
    return roster(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is RosterProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$rosterHash() => r'528a5b6d97df316d19a2293425b9975a84833839';

/// A team's roster (members + display names).

final class RosterFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<RosterMember>>, String> {
  RosterFamily._()
    : super(
        retry: null,
        name: r'rosterProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// A team's roster (members + display names).

  RosterProvider call(String teamId) =>
      RosterProvider._(argument: teamId, from: this);

  @override
  String toString() => r'rosterProvider';
}
