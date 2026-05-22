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

String _$teamsRepositoryHash() => r'c2e133288be2cabd751552d7ad1bc8c942f5ebf6';

@ProviderFor(createTeamUseCase)
final createTeamUseCaseProvider = CreateTeamUseCaseProvider._();

final class CreateTeamUseCaseProvider
    extends $FunctionalProvider<CreateTeam, CreateTeam, CreateTeam>
    with $Provider<CreateTeam> {
  CreateTeamUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'createTeamUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$createTeamUseCaseHash();

  @$internal
  @override
  $ProviderElement<CreateTeam> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CreateTeam create(Ref ref) {
    return createTeamUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CreateTeam value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CreateTeam>(value),
    );
  }
}

String _$createTeamUseCaseHash() => r'c045fad11d8851650e14bee2e7ed80bff22aefa3';

@ProviderFor(watchMyTeamsUseCase)
final watchMyTeamsUseCaseProvider = WatchMyTeamsUseCaseProvider._();

final class WatchMyTeamsUseCaseProvider
    extends $FunctionalProvider<WatchMyTeams, WatchMyTeams, WatchMyTeams>
    with $Provider<WatchMyTeams> {
  WatchMyTeamsUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'watchMyTeamsUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$watchMyTeamsUseCaseHash();

  @$internal
  @override
  $ProviderElement<WatchMyTeams> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  WatchMyTeams create(Ref ref) {
    return watchMyTeamsUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WatchMyTeams value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WatchMyTeams>(value),
    );
  }
}

String _$watchMyTeamsUseCaseHash() =>
    r'3f4399f7ff99007181715c940715e3f00c9c8d1a';

@ProviderFor(watchAllTeamsUseCase)
final watchAllTeamsUseCaseProvider = WatchAllTeamsUseCaseProvider._();

final class WatchAllTeamsUseCaseProvider
    extends $FunctionalProvider<WatchAllTeams, WatchAllTeams, WatchAllTeams>
    with $Provider<WatchAllTeams> {
  WatchAllTeamsUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'watchAllTeamsUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$watchAllTeamsUseCaseHash();

  @$internal
  @override
  $ProviderElement<WatchAllTeams> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  WatchAllTeams create(Ref ref) {
    return watchAllTeamsUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WatchAllTeams value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WatchAllTeams>(value),
    );
  }
}

String _$watchAllTeamsUseCaseHash() =>
    r'bcbc6bda50d85da26d02dc95a8e4df877b6436dd';

@ProviderFor(watchTeamUseCase)
final watchTeamUseCaseProvider = WatchTeamUseCaseProvider._();

final class WatchTeamUseCaseProvider
    extends $FunctionalProvider<WatchTeam, WatchTeam, WatchTeam>
    with $Provider<WatchTeam> {
  WatchTeamUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'watchTeamUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$watchTeamUseCaseHash();

  @$internal
  @override
  $ProviderElement<WatchTeam> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  WatchTeam create(Ref ref) {
    return watchTeamUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WatchTeam value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WatchTeam>(value),
    );
  }
}

String _$watchTeamUseCaseHash() => r'f6ec19e273fcf0eecdaeddcd25197062acac341e';

@ProviderFor(getTeamUseCase)
final getTeamUseCaseProvider = GetTeamUseCaseProvider._();

final class GetTeamUseCaseProvider
    extends $FunctionalProvider<GetTeam, GetTeam, GetTeam>
    with $Provider<GetTeam> {
  GetTeamUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'getTeamUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$getTeamUseCaseHash();

  @$internal
  @override
  $ProviderElement<GetTeam> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GetTeam create(Ref ref) {
    return getTeamUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetTeam value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetTeam>(value),
    );
  }
}

String _$getTeamUseCaseHash() => r'cff659c92f4300ede4499c85f7ee8fe2b1da1fef';

@ProviderFor(watchRosterUseCase)
final watchRosterUseCaseProvider = WatchRosterUseCaseProvider._();

final class WatchRosterUseCaseProvider
    extends $FunctionalProvider<WatchRoster, WatchRoster, WatchRoster>
    with $Provider<WatchRoster> {
  WatchRosterUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'watchRosterUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$watchRosterUseCaseHash();

  @$internal
  @override
  $ProviderElement<WatchRoster> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  WatchRoster create(Ref ref) {
    return watchRosterUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WatchRoster value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WatchRoster>(value),
    );
  }
}

String _$watchRosterUseCaseHash() =>
    r'1fe895fb01e0ac016638bd49e20a73a479e9ee0c';

@ProviderFor(addUnclaimedPlayerUseCase)
final addUnclaimedPlayerUseCaseProvider = AddUnclaimedPlayerUseCaseProvider._();

final class AddUnclaimedPlayerUseCaseProvider
    extends
        $FunctionalProvider<
          AddUnclaimedPlayer,
          AddUnclaimedPlayer,
          AddUnclaimedPlayer
        >
    with $Provider<AddUnclaimedPlayer> {
  AddUnclaimedPlayerUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'addUnclaimedPlayerUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$addUnclaimedPlayerUseCaseHash();

  @$internal
  @override
  $ProviderElement<AddUnclaimedPlayer> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AddUnclaimedPlayer create(Ref ref) {
    return addUnclaimedPlayerUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AddUnclaimedPlayer value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AddUnclaimedPlayer>(value),
    );
  }
}

String _$addUnclaimedPlayerUseCaseHash() =>
    r'a3b8e7bf6f98bdd92cdde523804487de4be19022';

@ProviderFor(removeMemberUseCase)
final removeMemberUseCaseProvider = RemoveMemberUseCaseProvider._();

final class RemoveMemberUseCaseProvider
    extends $FunctionalProvider<RemoveMember, RemoveMember, RemoveMember>
    with $Provider<RemoveMember> {
  RemoveMemberUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'removeMemberUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$removeMemberUseCaseHash();

  @$internal
  @override
  $ProviderElement<RemoveMember> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RemoveMember create(Ref ref) {
    return removeMemberUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RemoveMember value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RemoveMember>(value),
    );
  }
}

String _$removeMemberUseCaseHash() =>
    r'223b448d22fed7e22d9124b8d336beeb2d98deec';

@ProviderFor(setJerseyNumberUseCase)
final setJerseyNumberUseCaseProvider = SetJerseyNumberUseCaseProvider._();

final class SetJerseyNumberUseCaseProvider
    extends
        $FunctionalProvider<SetJerseyNumber, SetJerseyNumber, SetJerseyNumber>
    with $Provider<SetJerseyNumber> {
  SetJerseyNumberUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'setJerseyNumberUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$setJerseyNumberUseCaseHash();

  @$internal
  @override
  $ProviderElement<SetJerseyNumber> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SetJerseyNumber create(Ref ref) {
    return setJerseyNumberUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SetJerseyNumber value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SetJerseyNumber>(value),
    );
  }
}

String _$setJerseyNumberUseCaseHash() =>
    r'100a82492de49e11dc9c52fed2576571b33b395a';

@ProviderFor(setMemberRoleUseCase)
final setMemberRoleUseCaseProvider = SetMemberRoleUseCaseProvider._();

final class SetMemberRoleUseCaseProvider
    extends $FunctionalProvider<SetMemberRole, SetMemberRole, SetMemberRole>
    with $Provider<SetMemberRole> {
  SetMemberRoleUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'setMemberRoleUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$setMemberRoleUseCaseHash();

  @$internal
  @override
  $ProviderElement<SetMemberRole> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SetMemberRole create(Ref ref) {
    return setMemberRoleUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SetMemberRole value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SetMemberRole>(value),
    );
  }
}

String _$setMemberRoleUseCaseHash() =>
    r'd0991b1c1398512da7e107f2a47e5ccaf10cc43b';

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

String _$myTeamsHash() => r'2c6e28eab114c9c4d04b20d8b537a2229765b21e';

/// All cached teams (opponent picker).

@ProviderFor(allTeams)
final allTeamsProvider = AllTeamsProvider._();

/// All cached teams (opponent picker).

final class AllTeamsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Team>>,
          List<Team>,
          Stream<List<Team>>
        >
    with $FutureModifier<List<Team>>, $StreamProvider<List<Team>> {
  /// All cached teams (opponent picker).
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

String _$allTeamsHash() => r'3b977ccfee88e47c2a7f79133d32321f05e5e1d7';

/// A single team (hub view), streamed from local. Null if not cached.

@ProviderFor(team)
final teamProvider = TeamFamily._();

/// A single team (hub view), streamed from local. Null if not cached.

final class TeamProvider
    extends $FunctionalProvider<AsyncValue<Team?>, Team?, Stream<Team?>>
    with $FutureModifier<Team?>, $StreamProvider<Team?> {
  /// A single team (hub view), streamed from local. Null if not cached.
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

String _$teamHash() => r'33881b64e597b11b383a1d8960df7c91dc64b618';

/// A single team (hub view), streamed from local. Null if not cached.

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

  /// A single team (hub view), streamed from local. Null if not cached.

  TeamProvider call(String teamId) =>
      TeamProvider._(argument: teamId, from: this);

  @override
  String toString() => r'teamProvider';
}

/// A team's roster (members + names), streamed from local.

@ProviderFor(roster)
final rosterProvider = RosterFamily._();

/// A team's roster (members + names), streamed from local.

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
  /// A team's roster (members + names), streamed from local.
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

String _$rosterHash() => r'1349e5783565a164ce6f2cc68d9555812348e72e';

/// A team's roster (members + names), streamed from local.

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

  /// A team's roster (members + names), streamed from local.

  RosterProvider call(String teamId) =>
      RosterProvider._(argument: teamId, from: this);

  @override
  String toString() => r'rosterProvider';
}
