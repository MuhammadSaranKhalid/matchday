// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_membership_datasource_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(teamMembershipRemoteDataSource)
final teamMembershipRemoteDataSourceProvider =
    TeamMembershipRemoteDataSourceProvider._();

final class TeamMembershipRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          TeamMembershipRemoteDataSource,
          TeamMembershipRemoteDataSource,
          TeamMembershipRemoteDataSource
        >
    with $Provider<TeamMembershipRemoteDataSource> {
  TeamMembershipRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'teamMembershipRemoteDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$teamMembershipRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<TeamMembershipRemoteDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TeamMembershipRemoteDataSource create(Ref ref) {
    return teamMembershipRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TeamMembershipRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TeamMembershipRemoteDataSource>(
        value,
      ),
    );
  }
}

String _$teamMembershipRemoteDataSourceHash() =>
    r'2be5e72e65d53a1b1d3a071e825da662c6047132';
