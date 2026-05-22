// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'matches_datasource_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(matchesRemoteDataSource)
final matchesRemoteDataSourceProvider = MatchesRemoteDataSourceProvider._();

final class MatchesRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          MatchesRemoteDataSource,
          MatchesRemoteDataSource,
          MatchesRemoteDataSource
        >
    with $Provider<MatchesRemoteDataSource> {
  MatchesRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'matchesRemoteDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$matchesRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<MatchesRemoteDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MatchesRemoteDataSource create(Ref ref) {
    return matchesRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MatchesRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MatchesRemoteDataSource>(value),
    );
  }
}

String _$matchesRemoteDataSourceHash() =>
    r'82e29ea716805238a33591f14befcff1be63e192';
