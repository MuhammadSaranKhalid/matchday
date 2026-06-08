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
