// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'follows_datasource_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(followsRemoteDataSource)
final followsRemoteDataSourceProvider = FollowsRemoteDataSourceProvider._();

final class FollowsRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          FollowsRemoteDataSource,
          FollowsRemoteDataSource,
          FollowsRemoteDataSource
        >
    with $Provider<FollowsRemoteDataSource> {
  FollowsRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'followsRemoteDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$followsRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<FollowsRemoteDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FollowsRemoteDataSource create(Ref ref) {
    return followsRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FollowsRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FollowsRemoteDataSource>(value),
    );
  }
}

String _$followsRemoteDataSourceHash() =>
    r'52130fe3efa85f2058c5c4db73bdd960c3b8823a';
