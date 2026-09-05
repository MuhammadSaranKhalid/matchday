// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'follows_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The canonical [FollowsRepository] provider.
///
/// Returns the ABSTRACT type [FollowsRepository] — consumers never see the
/// implementation, per CLAUDE.md §5.3 DI rules.

@ProviderFor(followsRepository)
final followsRepositoryProvider = FollowsRepositoryProvider._();

/// The canonical [FollowsRepository] provider.
///
/// Returns the ABSTRACT type [FollowsRepository] — consumers never see the
/// implementation, per CLAUDE.md §5.3 DI rules.

final class FollowsRepositoryProvider
    extends
        $FunctionalProvider<
          FollowsRepository,
          FollowsRepository,
          FollowsRepository
        >
    with $Provider<FollowsRepository> {
  /// The canonical [FollowsRepository] provider.
  ///
  /// Returns the ABSTRACT type [FollowsRepository] — consumers never see the
  /// implementation, per CLAUDE.md §5.3 DI rules.
  FollowsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'followsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$followsRepositoryHash();

  @$internal
  @override
  $ProviderElement<FollowsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FollowsRepository create(Ref ref) {
    return followsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FollowsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FollowsRepository>(value),
    );
  }
}

String _$followsRepositoryHash() => r'f0454b3b168508561acaff881908469c5f16ea8c';

/// Autodispose family that checks whether the signed-in user follows a target.
///
/// Parameters are raw strings so Riverpod can serialise the family cache key
/// cleanly (no custom [FollowTarget] object in the family key).
///
/// [targetTypeWire] ∈ {'user', 'team', 'tournament'}
/// [targetId]       — UUID of the target entity
///
/// Throws [FailureWrapper] on [Left] so the consuming widget receives an
/// [AsyncError] and can render error copy without extra boilerplate.

@ProviderFor(isFollowing)
final isFollowingProvider = IsFollowingFamily._();

/// Autodispose family that checks whether the signed-in user follows a target.
///
/// Parameters are raw strings so Riverpod can serialise the family cache key
/// cleanly (no custom [FollowTarget] object in the family key).
///
/// [targetTypeWire] ∈ {'user', 'team', 'tournament'}
/// [targetId]       — UUID of the target entity
///
/// Throws [FailureWrapper] on [Left] so the consuming widget receives an
/// [AsyncError] and can render error copy without extra boilerplate.

final class IsFollowingProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Autodispose family that checks whether the signed-in user follows a target.
  ///
  /// Parameters are raw strings so Riverpod can serialise the family cache key
  /// cleanly (no custom [FollowTarget] object in the family key).
  ///
  /// [targetTypeWire] ∈ {'user', 'team', 'tournament'}
  /// [targetId]       — UUID of the target entity
  ///
  /// Throws [FailureWrapper] on [Left] so the consuming widget receives an
  /// [AsyncError] and can render error copy without extra boilerplate.
  IsFollowingProvider._({
    required IsFollowingFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'isFollowingProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$isFollowingHash();

  @override
  String toString() {
    return r'isFollowingProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    final argument = this.argument as (String, String);
    return isFollowing(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is IsFollowingProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$isFollowingHash() => r'd42164bfc89012735b7c9e9a063308b0e582d9bd';

/// Autodispose family that checks whether the signed-in user follows a target.
///
/// Parameters are raw strings so Riverpod can serialise the family cache key
/// cleanly (no custom [FollowTarget] object in the family key).
///
/// [targetTypeWire] ∈ {'user', 'team', 'tournament'}
/// [targetId]       — UUID of the target entity
///
/// Throws [FailureWrapper] on [Left] so the consuming widget receives an
/// [AsyncError] and can render error copy without extra boilerplate.

final class IsFollowingFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<bool>, (String, String)> {
  IsFollowingFamily._()
    : super(
        retry: null,
        name: r'isFollowingProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Autodispose family that checks whether the signed-in user follows a target.
  ///
  /// Parameters are raw strings so Riverpod can serialise the family cache key
  /// cleanly (no custom [FollowTarget] object in the family key).
  ///
  /// [targetTypeWire] ∈ {'user', 'team', 'tournament'}
  /// [targetId]       — UUID of the target entity
  ///
  /// Throws [FailureWrapper] on [Left] so the consuming widget receives an
  /// [AsyncError] and can render error copy without extra boilerplate.

  IsFollowingProvider call(String targetTypeWire, String targetId) =>
      IsFollowingProvider._(argument: (targetTypeWire, targetId), from: this);

  @override
  String toString() => r'isFollowingProvider';
}

/// Autodispose family that fetches a user's followers or following list.
///
/// Parameters are raw strings so Riverpod can serialise the family cache key
/// cleanly (no custom wrapper types in the key).
///
/// [userId]    — UUID of the profile to inspect.
/// [direction] — wire string, either 'followers' or 'following'.
///
/// Defaults to 100 entries with offset 0. For pagination, call
/// [FollowsRepository.getFollowList] directly through the repository provider.
///
/// Throws [FailureWrapper] on [Left] so the consuming widget receives an
/// [AsyncError] it can display without extra boilerplate.

@ProviderFor(followList)
final followListProvider = FollowListFamily._();

/// Autodispose family that fetches a user's followers or following list.
///
/// Parameters are raw strings so Riverpod can serialise the family cache key
/// cleanly (no custom wrapper types in the key).
///
/// [userId]    — UUID of the profile to inspect.
/// [direction] — wire string, either 'followers' or 'following'.
///
/// Defaults to 100 entries with offset 0. For pagination, call
/// [FollowsRepository.getFollowList] directly through the repository provider.
///
/// Throws [FailureWrapper] on [Left] so the consuming widget receives an
/// [AsyncError] it can display without extra boilerplate.

final class FollowListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<FollowListEntry>>,
          List<FollowListEntry>,
          FutureOr<List<FollowListEntry>>
        >
    with
        $FutureModifier<List<FollowListEntry>>,
        $FutureProvider<List<FollowListEntry>> {
  /// Autodispose family that fetches a user's followers or following list.
  ///
  /// Parameters are raw strings so Riverpod can serialise the family cache key
  /// cleanly (no custom wrapper types in the key).
  ///
  /// [userId]    — UUID of the profile to inspect.
  /// [direction] — wire string, either 'followers' or 'following'.
  ///
  /// Defaults to 100 entries with offset 0. For pagination, call
  /// [FollowsRepository.getFollowList] directly through the repository provider.
  ///
  /// Throws [FailureWrapper] on [Left] so the consuming widget receives an
  /// [AsyncError] it can display without extra boilerplate.
  FollowListProvider._({
    required FollowListFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'followListProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$followListHash();

  @override
  String toString() {
    return r'followListProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<FollowListEntry>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<FollowListEntry>> create(Ref ref) {
    final argument = this.argument as (String, String);
    return followList(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is FollowListProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$followListHash() => r'e2a21357a5ef4e87649099ecfcce42c231b867c4';

/// Autodispose family that fetches a user's followers or following list.
///
/// Parameters are raw strings so Riverpod can serialise the family cache key
/// cleanly (no custom wrapper types in the key).
///
/// [userId]    — UUID of the profile to inspect.
/// [direction] — wire string, either 'followers' or 'following'.
///
/// Defaults to 100 entries with offset 0. For pagination, call
/// [FollowsRepository.getFollowList] directly through the repository provider.
///
/// Throws [FailureWrapper] on [Left] so the consuming widget receives an
/// [AsyncError] it can display without extra boilerplate.

final class FollowListFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<FollowListEntry>>,
          (String, String)
        > {
  FollowListFamily._()
    : super(
        retry: null,
        name: r'followListProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Autodispose family that fetches a user's followers or following list.
  ///
  /// Parameters are raw strings so Riverpod can serialise the family cache key
  /// cleanly (no custom wrapper types in the key).
  ///
  /// [userId]    — UUID of the profile to inspect.
  /// [direction] — wire string, either 'followers' or 'following'.
  ///
  /// Defaults to 100 entries with offset 0. For pagination, call
  /// [FollowsRepository.getFollowList] directly through the repository provider.
  ///
  /// Throws [FailureWrapper] on [Left] so the consuming widget receives an
  /// [AsyncError] it can display without extra boilerplate.

  FollowListProvider call(String userId, String direction) =>
      FollowListProvider._(argument: (userId, direction), from: this);

  @override
  String toString() => r'followListProvider';
}

/// Autodispose family that fetches the followers and following counts for a
/// user profile.
///
/// [userId] — UUID of the profile to inspect.
///
/// Throws [FailureWrapper] on [Left] so the consuming widget receives an
/// [AsyncError] it can display without extra boilerplate.

@ProviderFor(followCounts)
final followCountsProvider = FollowCountsFamily._();

/// Autodispose family that fetches the followers and following counts for a
/// user profile.
///
/// [userId] — UUID of the profile to inspect.
///
/// Throws [FailureWrapper] on [Left] so the consuming widget receives an
/// [AsyncError] it can display without extra boilerplate.

final class FollowCountsProvider
    extends
        $FunctionalProvider<
          AsyncValue<FollowCounts>,
          FollowCounts,
          FutureOr<FollowCounts>
        >
    with $FutureModifier<FollowCounts>, $FutureProvider<FollowCounts> {
  /// Autodispose family that fetches the followers and following counts for a
  /// user profile.
  ///
  /// [userId] — UUID of the profile to inspect.
  ///
  /// Throws [FailureWrapper] on [Left] so the consuming widget receives an
  /// [AsyncError] it can display without extra boilerplate.
  FollowCountsProvider._({
    required FollowCountsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'followCountsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$followCountsHash();

  @override
  String toString() {
    return r'followCountsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<FollowCounts> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<FollowCounts> create(Ref ref) {
    final argument = this.argument as String;
    return followCounts(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is FollowCountsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$followCountsHash() => r'63cb71fbb5d388e70ab3cc20f42e9b6ab5576b61';

/// Autodispose family that fetches the followers and following counts for a
/// user profile.
///
/// [userId] — UUID of the profile to inspect.
///
/// Throws [FailureWrapper] on [Left] so the consuming widget receives an
/// [AsyncError] it can display without extra boilerplate.

final class FollowCountsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<FollowCounts>, String> {
  FollowCountsFamily._()
    : super(
        retry: null,
        name: r'followCountsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Autodispose family that fetches the followers and following counts for a
  /// user profile.
  ///
  /// [userId] — UUID of the profile to inspect.
  ///
  /// Throws [FailureWrapper] on [Left] so the consuming widget receives an
  /// [AsyncError] it can display without extra boilerplate.

  FollowCountsProvider call(String userId) =>
      FollowCountsProvider._(argument: userId, from: this);

  @override
  String toString() => r'followCountsProvider';
}

/// Team ids the signed-in user follows — half of the Matches board's
/// "For you" rule (the other half is tournaments you are in).

@ProviderFor(followedTeamIds)
final followedTeamIdsProvider = FollowedTeamIdsProvider._();

/// Team ids the signed-in user follows — half of the Matches board's
/// "For you" rule (the other half is tournaments you are in).

final class FollowedTeamIdsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Set<String>>,
          Set<String>,
          FutureOr<Set<String>>
        >
    with $FutureModifier<Set<String>>, $FutureProvider<Set<String>> {
  /// Team ids the signed-in user follows — half of the Matches board's
  /// "For you" rule (the other half is tournaments you are in).
  FollowedTeamIdsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'followedTeamIdsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$followedTeamIdsHash();

  @$internal
  @override
  $FutureProviderElement<Set<String>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Set<String>> create(Ref ref) {
    return followedTeamIds(ref);
  }
}

String _$followedTeamIdsHash() => r'e4c85e3df87878ce224fa6c1ab58398fa55bf352';

/// Whether the signed-in user wants notifications about a team.
///
/// Autodispose: a sheet that is open for four seconds should not pin a
/// subscription for the session. False when the user doesn't follow the team
/// — there is no row to carry the preference.

@ProviderFor(teamNotificationsEnabled)
final teamNotificationsEnabledProvider = TeamNotificationsEnabledFamily._();

/// Whether the signed-in user wants notifications about a team.
///
/// Autodispose: a sheet that is open for four seconds should not pin a
/// subscription for the session. False when the user doesn't follow the team
/// — there is no row to carry the preference.

final class TeamNotificationsEnabledProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Whether the signed-in user wants notifications about a team.
  ///
  /// Autodispose: a sheet that is open for four seconds should not pin a
  /// subscription for the session. False when the user doesn't follow the team
  /// — there is no row to carry the preference.
  TeamNotificationsEnabledProvider._({
    required TeamNotificationsEnabledFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'teamNotificationsEnabledProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$teamNotificationsEnabledHash();

  @override
  String toString() {
    return r'teamNotificationsEnabledProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    final argument = this.argument as String;
    return teamNotificationsEnabled(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TeamNotificationsEnabledProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$teamNotificationsEnabledHash() =>
    r'4fa0a01250a9725bc494ed5421da307e8b852c3c';

/// Whether the signed-in user wants notifications about a team.
///
/// Autodispose: a sheet that is open for four seconds should not pin a
/// subscription for the session. False when the user doesn't follow the team
/// — there is no row to carry the preference.

final class TeamNotificationsEnabledFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<bool>, String> {
  TeamNotificationsEnabledFamily._()
    : super(
        retry: null,
        name: r'teamNotificationsEnabledProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Whether the signed-in user wants notifications about a team.
  ///
  /// Autodispose: a sheet that is open for four seconds should not pin a
  /// subscription for the session. False when the user doesn't follow the team
  /// — there is no row to carry the preference.

  TeamNotificationsEnabledProvider call(String teamId) =>
      TeamNotificationsEnabledProvider._(argument: teamId, from: this);

  @override
  String toString() => r'teamNotificationsEnabledProvider';
}
