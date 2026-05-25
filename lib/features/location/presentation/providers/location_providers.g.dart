// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(locationRepository)
final locationRepositoryProvider = LocationRepositoryProvider._();

final class LocationRepositoryProvider
    extends
        $FunctionalProvider<
          LocationRepository,
          LocationRepository,
          LocationRepository
        >
    with $Provider<LocationRepository> {
  LocationRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'locationRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$locationRepositoryHash();

  @$internal
  @override
  $ProviderElement<LocationRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LocationRepository create(Ref ref) {
    return locationRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LocationRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LocationRepository>(value),
    );
  }
}

String _$locationRepositoryHash() =>
    r'115446842a75dd5e965b60a6d3dffbe04cde8287';

@ProviderFor(autocompletePlacesUseCase)
final autocompletePlacesUseCaseProvider = AutocompletePlacesUseCaseProvider._();

final class AutocompletePlacesUseCaseProvider
    extends
        $FunctionalProvider<
          AutocompletePlaces,
          AutocompletePlaces,
          AutocompletePlaces
        >
    with $Provider<AutocompletePlaces> {
  AutocompletePlacesUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'autocompletePlacesUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$autocompletePlacesUseCaseHash();

  @$internal
  @override
  $ProviderElement<AutocompletePlaces> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AutocompletePlaces create(Ref ref) {
    return autocompletePlacesUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AutocompletePlaces value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AutocompletePlaces>(value),
    );
  }
}

String _$autocompletePlacesUseCaseHash() =>
    r'273b4cb56102ce19737361be04ec4278ff7844c1';

@ProviderFor(getPlaceDetailsUseCase)
final getPlaceDetailsUseCaseProvider = GetPlaceDetailsUseCaseProvider._();

final class GetPlaceDetailsUseCaseProvider
    extends
        $FunctionalProvider<GetPlaceDetails, GetPlaceDetails, GetPlaceDetails>
    with $Provider<GetPlaceDetails> {
  GetPlaceDetailsUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'getPlaceDetailsUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$getPlaceDetailsUseCaseHash();

  @$internal
  @override
  $ProviderElement<GetPlaceDetails> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GetPlaceDetails create(Ref ref) {
    return getPlaceDetailsUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetPlaceDetails value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetPlaceDetails>(value),
    );
  }
}

String _$getPlaceDetailsUseCaseHash() =>
    r'ed2ca625e4c8875a74547b08b5daf66f1e69194b';

@ProviderFor(getCurrentLocationUseCase)
final getCurrentLocationUseCaseProvider = GetCurrentLocationUseCaseProvider._();

final class GetCurrentLocationUseCaseProvider
    extends
        $FunctionalProvider<
          GetCurrentLocation,
          GetCurrentLocation,
          GetCurrentLocation
        >
    with $Provider<GetCurrentLocation> {
  GetCurrentLocationUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'getCurrentLocationUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$getCurrentLocationUseCaseHash();

  @$internal
  @override
  $ProviderElement<GetCurrentLocation> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GetCurrentLocation create(Ref ref) {
    return getCurrentLocationUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetCurrentLocation value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetCurrentLocation>(value),
    );
  }
}

String _$getCurrentLocationUseCaseHash() =>
    r'2333ba2329b3c742f78d92b31c7b93f79d18d652';

@ProviderFor(geocodeAddressUseCase)
final geocodeAddressUseCaseProvider = GeocodeAddressUseCaseProvider._();

final class GeocodeAddressUseCaseProvider
    extends $FunctionalProvider<GeocodeAddress, GeocodeAddress, GeocodeAddress>
    with $Provider<GeocodeAddress> {
  GeocodeAddressUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'geocodeAddressUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$geocodeAddressUseCaseHash();

  @$internal
  @override
  $ProviderElement<GeocodeAddress> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GeocodeAddress create(Ref ref) {
    return geocodeAddressUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GeocodeAddress value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GeocodeAddress>(value),
    );
  }
}

String _$geocodeAddressUseCaseHash() =>
    r'f7201f7c1db10c18b1fc8c41a76ac3034bc790b1';
