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

/// Team invites sent to players for a team.

@ProviderFor(teamPendingInvites)
final teamPendingInvitesProvider = TeamPendingInvitesFamily._();

/// Team invites sent to players for a team.

final class TeamPendingInvitesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Map<String, dynamic>>>,
          List<Map<String, dynamic>>,
          FutureOr<List<Map<String, dynamic>>>
        >
    with
        $FutureModifier<List<Map<String, dynamic>>>,
        $FutureProvider<List<Map<String, dynamic>>> {
  /// Team invites sent to players for a team.
  TeamPendingInvitesProvider._({
    required TeamPendingInvitesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'teamPendingInvitesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$teamPendingInvitesHash();

  @override
  String toString() {
    return r'teamPendingInvitesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Map<String, dynamic>>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Map<String, dynamic>>> create(Ref ref) {
    final argument = this.argument as String;
    return teamPendingInvites(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TeamPendingInvitesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$teamPendingInvitesHash() =>
    r'eb514b43ac4c2c0e5099d917e64b81f0073d6ef4';

/// Team invites sent to players for a team.

final class TeamPendingInvitesFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<Map<String, dynamic>>>,
          String
        > {
  TeamPendingInvitesFamily._()
    : super(
        retry: null,
        name: r'teamPendingInvitesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Team invites sent to players for a team.

  TeamPendingInvitesProvider call(String teamId) =>
      TeamPendingInvitesProvider._(argument: teamId, from: this);

  @override
  String toString() => r'teamPendingInvitesProvider';
}

/// Claim requests from users claiming unclaimed roster spots for a team.

@ProviderFor(teamPendingClaimRequests)
final teamPendingClaimRequestsProvider = TeamPendingClaimRequestsFamily._();

/// Claim requests from users claiming unclaimed roster spots for a team.

final class TeamPendingClaimRequestsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Map<String, dynamic>>>,
          List<Map<String, dynamic>>,
          FutureOr<List<Map<String, dynamic>>>
        >
    with
        $FutureModifier<List<Map<String, dynamic>>>,
        $FutureProvider<List<Map<String, dynamic>>> {
  /// Claim requests from users claiming unclaimed roster spots for a team.
  TeamPendingClaimRequestsProvider._({
    required TeamPendingClaimRequestsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'teamPendingClaimRequestsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$teamPendingClaimRequestsHash();

  @override
  String toString() {
    return r'teamPendingClaimRequestsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Map<String, dynamic>>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Map<String, dynamic>>> create(Ref ref) {
    final argument = this.argument as String;
    return teamPendingClaimRequests(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TeamPendingClaimRequestsProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$teamPendingClaimRequestsHash() =>
    r'74192f4dec85436895cc34af34b0dd34e35cb7a6';

/// Claim requests from users claiming unclaimed roster spots for a team.

final class TeamPendingClaimRequestsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<Map<String, dynamic>>>,
          String
        > {
  TeamPendingClaimRequestsFamily._()
    : super(
        retry: null,
        name: r'teamPendingClaimRequestsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Claim requests from users claiming unclaimed roster spots for a team.

  TeamPendingClaimRequestsProvider call(String teamId) =>
      TeamPendingClaimRequestsProvider._(argument: teamId, from: this);

  @override
  String toString() => r'teamPendingClaimRequestsProvider';
}

/// Join requests from players asking to join a team.

@ProviderFor(teamPendingJoinRequests)
final teamPendingJoinRequestsProvider = TeamPendingJoinRequestsFamily._();

/// Join requests from players asking to join a team.

final class TeamPendingJoinRequestsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Map<String, dynamic>>>,
          List<Map<String, dynamic>>,
          FutureOr<List<Map<String, dynamic>>>
        >
    with
        $FutureModifier<List<Map<String, dynamic>>>,
        $FutureProvider<List<Map<String, dynamic>>> {
  /// Join requests from players asking to join a team.
  TeamPendingJoinRequestsProvider._({
    required TeamPendingJoinRequestsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'teamPendingJoinRequestsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$teamPendingJoinRequestsHash();

  @override
  String toString() {
    return r'teamPendingJoinRequestsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Map<String, dynamic>>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Map<String, dynamic>>> create(Ref ref) {
    final argument = this.argument as String;
    return teamPendingJoinRequests(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TeamPendingJoinRequestsProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$teamPendingJoinRequestsHash() =>
    r'b25e195951ca1fe6a8cce99671bb3fd5665ea7a9';

/// Join requests from players asking to join a team.

final class TeamPendingJoinRequestsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<Map<String, dynamic>>>,
          String
        > {
  TeamPendingJoinRequestsFamily._()
    : super(
        retry: null,
        name: r'teamPendingJoinRequestsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Join requests from players asking to join a team.

  TeamPendingJoinRequestsProvider call(String teamId) =>
      TeamPendingJoinRequestsProvider._(argument: teamId, from: this);

  @override
  String toString() => r'teamPendingJoinRequestsProvider';
}

/// Real-time stream of all teams affiliated with a user (captained and played for).

@ProviderFor(userAffiliatedTeams)
final userAffiliatedTeamsProvider = UserAffiliatedTeamsFamily._();

/// Real-time stream of all teams affiliated with a user (captained and played for).

final class UserAffiliatedTeamsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<UserTeamAffiliation>>,
          List<UserTeamAffiliation>,
          Stream<List<UserTeamAffiliation>>
        >
    with
        $FutureModifier<List<UserTeamAffiliation>>,
        $StreamProvider<List<UserTeamAffiliation>> {
  /// Real-time stream of all teams affiliated with a user (captained and played for).
  UserAffiliatedTeamsProvider._({
    required UserAffiliatedTeamsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'userAffiliatedTeamsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$userAffiliatedTeamsHash();

  @override
  String toString() {
    return r'userAffiliatedTeamsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<UserTeamAffiliation>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<UserTeamAffiliation>> create(Ref ref) {
    final argument = this.argument as String;
    return userAffiliatedTeams(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is UserAffiliatedTeamsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$userAffiliatedTeamsHash() =>
    r'9bc33c4b51c76ce306db137b52571128c7da64e1';

/// Real-time stream of all teams affiliated with a user (captained and played for).

final class UserAffiliatedTeamsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<UserTeamAffiliation>>, String> {
  UserAffiliatedTeamsFamily._()
    : super(
        retry: null,
        name: r'userAffiliatedTeamsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Real-time stream of all teams affiliated with a user (captained and played for).

  UserAffiliatedTeamsProvider call(String userId) =>
      UserAffiliatedTeamsProvider._(argument: userId, from: this);

  @override
  String toString() => r'userAffiliatedTeamsProvider';
}
