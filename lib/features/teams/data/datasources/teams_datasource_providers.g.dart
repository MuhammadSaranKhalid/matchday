// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'teams_datasource_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Own file so the sync provider and the repository provider can both depend
/// on these without an import cycle (mirrors the todos pattern).

@ProviderFor(teamsLocalDataSource)
final teamsLocalDataSourceProvider = TeamsLocalDataSourceProvider._();

/// Own file so the sync provider and the repository provider can both depend
/// on these without an import cycle (mirrors the todos pattern).

final class TeamsLocalDataSourceProvider
    extends
        $FunctionalProvider<
          TeamsLocalDataSource,
          TeamsLocalDataSource,
          TeamsLocalDataSource
        >
    with $Provider<TeamsLocalDataSource> {
  /// Own file so the sync provider and the repository provider can both depend
  /// on these without an import cycle (mirrors the todos pattern).
  TeamsLocalDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'teamsLocalDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$teamsLocalDataSourceHash();

  @$internal
  @override
  $ProviderElement<TeamsLocalDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TeamsLocalDataSource create(Ref ref) {
    return teamsLocalDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TeamsLocalDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TeamsLocalDataSource>(value),
    );
  }
}

String _$teamsLocalDataSourceHash() =>
    r'921ed0d727799abd5b618fc295c49f00ff43bb6f';

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
