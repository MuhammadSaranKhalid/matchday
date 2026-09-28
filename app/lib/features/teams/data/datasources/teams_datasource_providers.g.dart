// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'teams_datasource_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(teamsRemoteDataSource)
final teamsRemoteDataSourceProvider = TeamsRemoteDataSourceProvider._();

final class TeamsRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          TeamsRemoteDataSource,
          TeamsRemoteDataSource,
          TeamsRemoteDataSource
        >
    with $Provider<TeamsRemoteDataSource> {
  TeamsRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'teamsRemoteDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$teamsRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<TeamsRemoteDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TeamsRemoteDataSource create(Ref ref) {
    return teamsRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TeamsRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TeamsRemoteDataSource>(value),
    );
  }
}

String _$teamsRemoteDataSourceHash() =>
    r'da8bef472c7da455a082a483726022f3dcf9cea3';
