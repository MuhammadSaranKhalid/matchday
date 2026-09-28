// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cricket_player_profile_repository_impl.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(cricketPlayerProfileRemoteDataSource)
final cricketPlayerProfileRemoteDataSourceProvider =
    CricketPlayerProfileRemoteDataSourceProvider._();

final class CricketPlayerProfileRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          CricketPlayerProfileRemoteDataSource,
          CricketPlayerProfileRemoteDataSource,
          CricketPlayerProfileRemoteDataSource
        >
    with $Provider<CricketPlayerProfileRemoteDataSource> {
  CricketPlayerProfileRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cricketPlayerProfileRemoteDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() =>
      _$cricketPlayerProfileRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<CricketPlayerProfileRemoteDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CricketPlayerProfileRemoteDataSource create(Ref ref) {
    return cricketPlayerProfileRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CricketPlayerProfileRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<CricketPlayerProfileRemoteDataSource>(value),
    );
  }
}

String _$cricketPlayerProfileRemoteDataSourceHash() =>
    r'334f31693111251be9fbfe786e4809e240f5c216';

@ProviderFor(cricketPlayerProfileRepository)
final cricketPlayerProfileRepositoryProvider =
    CricketPlayerProfileRepositoryProvider._();

final class CricketPlayerProfileRepositoryProvider
    extends
        $FunctionalProvider<
          CricketPlayerProfileRepository,
          CricketPlayerProfileRepository,
          CricketPlayerProfileRepository
        >
    with $Provider<CricketPlayerProfileRepository> {
  CricketPlayerProfileRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cricketPlayerProfileRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cricketPlayerProfileRepositoryHash();

  @$internal
  @override
  $ProviderElement<CricketPlayerProfileRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CricketPlayerProfileRepository create(Ref ref) {
    return cricketPlayerProfileRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CricketPlayerProfileRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CricketPlayerProfileRepository>(
        value,
      ),
    );
  }
}

String _$cricketPlayerProfileRepositoryHash() =>
    r'e7ae76484415218a3912859c7aa6828eee1dec6c';
