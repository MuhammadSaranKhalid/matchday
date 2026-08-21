// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'matches_local_datasource.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(matchesLocalDataSource)
final matchesLocalDataSourceProvider = MatchesLocalDataSourceProvider._();

final class MatchesLocalDataSourceProvider
    extends
        $FunctionalProvider<
          MatchesLocalDataSource,
          MatchesLocalDataSource,
          MatchesLocalDataSource
        >
    with $Provider<MatchesLocalDataSource> {
  MatchesLocalDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'matchesLocalDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$matchesLocalDataSourceHash();

  @$internal
  @override
  $ProviderElement<MatchesLocalDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MatchesLocalDataSource create(Ref ref) {
    return matchesLocalDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MatchesLocalDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MatchesLocalDataSource>(value),
    );
  }
}

String _$matchesLocalDataSourceHash() =>
    r'1272d728140b113f9e4877a5834400ddbca581a0';
