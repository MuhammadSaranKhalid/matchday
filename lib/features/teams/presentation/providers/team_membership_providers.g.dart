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
