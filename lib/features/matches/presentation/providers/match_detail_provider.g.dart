// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_detail_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Match Detail provider.
///
/// IMPORTANT ARCHITECTURE:
///
/// The OLD implementation primarily converted:
///
/// MyMatchesView -> PvMatch
///
/// That is a list-card projection and throws away important match state and
/// effective capabilities.
///
/// Real fixtures are now built from:
///
/// Match
/// + teams
/// + viewer memberships
/// + current Cricket phase
/// + effective RBAC
///
/// Pending challenge/request IDs still fall back to MyMatchesView because they
/// are not yet real `matches` rows.

@ProviderFor(matchDetail)
final matchDetailProvider = MatchDetailFamily._();

/// Match Detail provider.
///
/// IMPORTANT ARCHITECTURE:
///
/// The OLD implementation primarily converted:
///
/// MyMatchesView -> PvMatch
///
/// That is a list-card projection and throws away important match state and
/// effective capabilities.
///
/// Real fixtures are now built from:
///
/// Match
/// + teams
/// + viewer memberships
/// + current Cricket phase
/// + effective RBAC
///
/// Pending challenge/request IDs still fall back to MyMatchesView because they
/// are not yet real `matches` rows.

final class MatchDetailProvider
    extends
        $FunctionalProvider<AsyncValue<PvMatch?>, PvMatch?, FutureOr<PvMatch?>>
    with $FutureModifier<PvMatch?>, $FutureProvider<PvMatch?> {
  /// Match Detail provider.
  ///
  /// IMPORTANT ARCHITECTURE:
  ///
  /// The OLD implementation primarily converted:
  ///
  /// MyMatchesView -> PvMatch
  ///
  /// That is a list-card projection and throws away important match state and
  /// effective capabilities.
  ///
  /// Real fixtures are now built from:
  ///
  /// Match
  /// + teams
  /// + viewer memberships
  /// + current Cricket phase
  /// + effective RBAC
  ///
  /// Pending challenge/request IDs still fall back to MyMatchesView because they
  /// are not yet real `matches` rows.
  MatchDetailProvider._({
    required MatchDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'matchDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$matchDetailHash();

  @override
  String toString() {
    return r'matchDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<PvMatch?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<PvMatch?> create(Ref ref) {
    final argument = this.argument as String;
    return matchDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MatchDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$matchDetailHash() => r'b69af523cdeabbd5a75233bbbb44a45e0299e319';

/// Match Detail provider.
///
/// IMPORTANT ARCHITECTURE:
///
/// The OLD implementation primarily converted:
///
/// MyMatchesView -> PvMatch
///
/// That is a list-card projection and throws away important match state and
/// effective capabilities.
///
/// Real fixtures are now built from:
///
/// Match
/// + teams
/// + viewer memberships
/// + current Cricket phase
/// + effective RBAC
///
/// Pending challenge/request IDs still fall back to MyMatchesView because they
/// are not yet real `matches` rows.

final class MatchDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<PvMatch?>, String> {
  MatchDetailFamily._()
    : super(
        retry: null,
        name: r'matchDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Match Detail provider.
  ///
  /// IMPORTANT ARCHITECTURE:
  ///
  /// The OLD implementation primarily converted:
  ///
  /// MyMatchesView -> PvMatch
  ///
  /// That is a list-card projection and throws away important match state and
  /// effective capabilities.
  ///
  /// Real fixtures are now built from:
  ///
  /// Match
  /// + teams
  /// + viewer memberships
  /// + current Cricket phase
  /// + effective RBAC
  ///
  /// Pending challenge/request IDs still fall back to MyMatchesView because they
  /// are not yet real `matches` rows.

  MatchDetailProvider call(String matchId) =>
      MatchDetailProvider._(argument: matchId, from: this);

  @override
  String toString() => r'matchDetailProvider';
}
