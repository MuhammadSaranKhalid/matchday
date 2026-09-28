// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location_datasource_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(placesRemoteDataSource)
final placesRemoteDataSourceProvider = PlacesRemoteDataSourceProvider._();

final class PlacesRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          PlacesRemoteDataSource,
          PlacesRemoteDataSource,
          PlacesRemoteDataSource
        >
    with $Provider<PlacesRemoteDataSource> {
  PlacesRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'placesRemoteDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$placesRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<PlacesRemoteDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PlacesRemoteDataSource create(Ref ref) {
    return placesRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlacesRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlacesRemoteDataSource>(value),
    );
  }
}

String _$placesRemoteDataSourceHash() =>
    r'c40920a279700e6e961b2c041fc671c1cd432053';

@ProviderFor(deviceLocationDataSource)
final deviceLocationDataSourceProvider = DeviceLocationDataSourceProvider._();

final class DeviceLocationDataSourceProvider
    extends
        $FunctionalProvider<
          DeviceLocationDataSource,
          DeviceLocationDataSource,
          DeviceLocationDataSource
        >
    with $Provider<DeviceLocationDataSource> {
  DeviceLocationDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deviceLocationDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deviceLocationDataSourceHash();

  @$internal
  @override
  $ProviderElement<DeviceLocationDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DeviceLocationDataSource create(Ref ref) {
    return deviceLocationDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DeviceLocationDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DeviceLocationDataSource>(value),
    );
  }
}

String _$deviceLocationDataSourceHash() =>
    r'645b04826246ef99dfdf20e0544d41a8619494fc';
