// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_membership_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(teamMembershipRepository)
final teamMembershipRepositoryProvider = TeamMembershipRepositoryProvider._();

final class TeamMembershipRepositoryProvider
    extends
        $FunctionalProvider<
          TeamMembershipRepository,
          TeamMembershipRepository,
          TeamMembershipRepository
        >
    with $Provider<TeamMembershipRepository> {
  TeamMembershipRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'teamMembershipRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$teamMembershipRepositoryHash();

  @$internal
  @override
  $ProviderElement<TeamMembershipRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TeamMembershipRepository create(Ref ref) {
    return teamMembershipRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TeamMembershipRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TeamMembershipRepository>(value),
    );
  }
}

String _$teamMembershipRepositoryHash() =>
    r'154a141dc235412afd0a550b2647520a08370740';

@ProviderFor(currentUserTeamMemberships)
final currentUserTeamMembershipsProvider =
    CurrentUserTeamMembershipsProvider._();

final class CurrentUserTeamMembershipsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TeamMembership>>,
          List<TeamMembership>,
          FutureOr<List<TeamMembership>>
        >
    with
        $FutureModifier<List<TeamMembership>>,
        $FutureProvider<List<TeamMembership>> {
  CurrentUserTeamMembershipsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentUserTeamMembershipsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentUserTeamMembershipsHash();

  @$internal
  @override
  $FutureProviderElement<List<TeamMembership>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<TeamMembership>> create(Ref ref) {
    return currentUserTeamMemberships(ref);
  }
}

String _$currentUserTeamMembershipsHash() =>
    r'e0833559313491a3973edd0ac30cfec1e97d9b34';

@ProviderFor(userTeamMemberships)
final userTeamMembershipsProvider = UserTeamMembershipsFamily._();

final class UserTeamMembershipsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TeamMembership>>,
          List<TeamMembership>,
          FutureOr<List<TeamMembership>>
        >
    with
        $FutureModifier<List<TeamMembership>>,
        $FutureProvider<List<TeamMembership>> {
  UserTeamMembershipsProvider._({
    required UserTeamMembershipsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'userTeamMembershipsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$userTeamMembershipsHash();

  @override
  String toString() {
    return r'userTeamMembershipsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<TeamMembership>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<TeamMembership>> create(Ref ref) {
    final argument = this.argument as String;
    return userTeamMemberships(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is UserTeamMembershipsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$userTeamMembershipsHash() =>
    r'a4b49678ea1e8207fe503e12b131bb5e65829386';

final class UserTeamMembershipsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<TeamMembership>>, String> {
  UserTeamMembershipsFamily._()
    : super(
        retry: null,
        name: r'userTeamMembershipsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  UserTeamMembershipsProvider call(String userId) =>
      UserTeamMembershipsProvider._(argument: userId, from: this);

  @override
  String toString() => r'userTeamMembershipsProvider';
}

@ProviderFor(currentTeamMembership)
final currentTeamMembershipProvider = CurrentTeamMembershipFamily._();

final class CurrentTeamMembershipProvider
    extends
        $FunctionalProvider<
          AsyncValue<TeamMembership?>,
          TeamMembership?,
          FutureOr<TeamMembership?>
        >
    with $FutureModifier<TeamMembership?>, $FutureProvider<TeamMembership?> {
  CurrentTeamMembershipProvider._({
    required CurrentTeamMembershipFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'currentTeamMembershipProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$currentTeamMembershipHash();

  @override
  String toString() {
    return r'currentTeamMembershipProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<TeamMembership?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<TeamMembership?> create(Ref ref) {
    final argument = this.argument as String;
    return currentTeamMembership(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CurrentTeamMembershipProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$currentTeamMembershipHash() =>
    r'f7e6a639615fc95bba70497308b0f9cfc3390a2d';

final class CurrentTeamMembershipFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<TeamMembership?>, String> {
  CurrentTeamMembershipFamily._()
    : super(
        retry: null,
        name: r'currentTeamMembershipProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CurrentTeamMembershipProvider call(String teamId) =>
      CurrentTeamMembershipProvider._(argument: teamId, from: this);

  @override
  String toString() => r'currentTeamMembershipProvider';
}

@ProviderFor(roster)
final rosterProvider = RosterFamily._();

final class RosterProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<RosterMember>>,
          List<RosterMember>,
          FutureOr<List<RosterMember>>
        >
    with
        $FutureModifier<List<RosterMember>>,
        $FutureProvider<List<RosterMember>> {
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
  $FutureProviderElement<List<RosterMember>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<RosterMember>> create(Ref ref) {
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

String _$rosterHash() => r'bf25d001225cb11c6838bb033533f24353012165';

final class RosterFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<RosterMember>>, String> {
  RosterFamily._()
    : super(
        retry: null,
        name: r'rosterProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  RosterProvider call(String teamId) =>
      RosterProvider._(argument: teamId, from: this);

  @override
  String toString() => r'rosterProvider';
}

@ProviderFor(myPendingInviteForTeam)
final myPendingInviteForTeamProvider = MyPendingInviteForTeamFamily._();

final class MyPendingInviteForTeamProvider
    extends
        $FunctionalProvider<
          AsyncValue<TeamInvite?>,
          TeamInvite?,
          FutureOr<TeamInvite?>
        >
    with $FutureModifier<TeamInvite?>, $FutureProvider<TeamInvite?> {
  MyPendingInviteForTeamProvider._({
    required MyPendingInviteForTeamFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'myPendingInviteForTeamProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$myPendingInviteForTeamHash();

  @override
  String toString() {
    return r'myPendingInviteForTeamProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<TeamInvite?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<TeamInvite?> create(Ref ref) {
    final argument = this.argument as String;
    return myPendingInviteForTeam(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MyPendingInviteForTeamProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$myPendingInviteForTeamHash() =>
    r'01c016f4f4c12a3f7099b41c7c7bad908262f702';

final class MyPendingInviteForTeamFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<TeamInvite?>, String> {
  MyPendingInviteForTeamFamily._()
    : super(
        retry: null,
        name: r'myPendingInviteForTeamProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  MyPendingInviteForTeamProvider call(String teamId) =>
      MyPendingInviteForTeamProvider._(argument: teamId, from: this);

  @override
  String toString() => r'myPendingInviteForTeamProvider';
}

@ProviderFor(teamPendingInvites)
final teamPendingInvitesProvider = TeamPendingInvitesFamily._();

final class TeamPendingInvitesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TeamInvite>>,
          List<TeamInvite>,
          FutureOr<List<TeamInvite>>
        >
    with $FutureModifier<List<TeamInvite>>, $FutureProvider<List<TeamInvite>> {
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
  $FutureProviderElement<List<TeamInvite>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<TeamInvite>> create(Ref ref) {
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
    r'9957bd77a0dfe2354a333229dd2e5c4424ef60aa';

final class TeamPendingInvitesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<TeamInvite>>, String> {
  TeamPendingInvitesFamily._()
    : super(
        retry: null,
        name: r'teamPendingInvitesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TeamPendingInvitesProvider call(String teamId) =>
      TeamPendingInvitesProvider._(argument: teamId, from: this);

  @override
  String toString() => r'teamPendingInvitesProvider';
}

@ProviderFor(teamPendingClaimRequests)
final teamPendingClaimRequestsProvider = TeamPendingClaimRequestsFamily._();

final class TeamPendingClaimRequestsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TeamClaimRequest>>,
          List<TeamClaimRequest>,
          FutureOr<List<TeamClaimRequest>>
        >
    with
        $FutureModifier<List<TeamClaimRequest>>,
        $FutureProvider<List<TeamClaimRequest>> {
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
  $FutureProviderElement<List<TeamClaimRequest>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<TeamClaimRequest>> create(Ref ref) {
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
    r'241304ba549d8cf2213ac5e871efb93b3fdbdc5a';

final class TeamPendingClaimRequestsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<TeamClaimRequest>>, String> {
  TeamPendingClaimRequestsFamily._()
    : super(
        retry: null,
        name: r'teamPendingClaimRequestsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TeamPendingClaimRequestsProvider call(String teamId) =>
      TeamPendingClaimRequestsProvider._(argument: teamId, from: this);

  @override
  String toString() => r'teamPendingClaimRequestsProvider';
}

@ProviderFor(teamPendingJoinRequests)
final teamPendingJoinRequestsProvider = TeamPendingJoinRequestsFamily._();

final class TeamPendingJoinRequestsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TeamJoinRequest>>,
          List<TeamJoinRequest>,
          FutureOr<List<TeamJoinRequest>>
        >
    with
        $FutureModifier<List<TeamJoinRequest>>,
        $FutureProvider<List<TeamJoinRequest>> {
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
  $FutureProviderElement<List<TeamJoinRequest>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<TeamJoinRequest>> create(Ref ref) {
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
    r'5ab4360f297271a16b2eb943bf76ff384bf7b2d4';

final class TeamPendingJoinRequestsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<TeamJoinRequest>>, String> {
  TeamPendingJoinRequestsFamily._()
    : super(
        retry: null,
        name: r'teamPendingJoinRequestsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TeamPendingJoinRequestsProvider call(String teamId) =>
      TeamPendingJoinRequestsProvider._(argument: teamId, from: this);

  @override
  String toString() => r'teamPendingJoinRequestsProvider';
}
