// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'explore_datasource_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// DI-only file (CLAUDE.md Rule 5): the data source itself takes a plain
/// constructor parameter and knows nothing about Riverpod.

@ProviderFor(exploreRemoteDataSource)
final exploreRemoteDataSourceProvider = ExploreRemoteDataSourceProvider._();

/// DI-only file (CLAUDE.md Rule 5): the data source itself takes a plain
/// constructor parameter and knows nothing about Riverpod.

final class ExploreRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          ExploreRemoteDataSource,
          ExploreRemoteDataSource,
          ExploreRemoteDataSource
        >
    with $Provider<ExploreRemoteDataSource> {
  /// DI-only file (CLAUDE.md Rule 5): the data source itself takes a plain
  /// constructor parameter and knows nothing about Riverpod.
  ExploreRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'exploreRemoteDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$exploreRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<ExploreRemoteDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ExploreRemoteDataSource create(Ref ref) {
    return exploreRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ExploreRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ExploreRemoteDataSource>(value),
    );
  }
}

String _$exploreRemoteDataSourceHash() =>
    r'c20b7d68d1daa00ca35a2d466383bcd963c8ce44';
