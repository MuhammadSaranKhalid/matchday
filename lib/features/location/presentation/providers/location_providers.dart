import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/datasources/location_datasource_providers.dart';
import '../../data/repositories/location_repository_impl.dart';
import '../../domain/repositories/location_repository.dart';
import '../../domain/usecases/autocomplete_places.dart';
import '../../domain/usecases/geocode_address.dart';
import '../../domain/usecases/get_current_location.dart';
import '../../domain/usecases/get_place_details.dart';

// This providers file is the feature's public presentation API. Consumers in
// other features (e.g. onboarding, per CLAUDE.md §6.6) read the use cases via
// the providers below; the use-case `Params` types are re-exported here so
// callers never have to import this feature's domain/usecases directly.
export '../../domain/usecases/autocomplete_places.dart'
    show AutocompletePlaces, AutocompletePlacesParams;
export '../../domain/usecases/geocode_address.dart' show GeocodeAddressParams;
export '../../domain/usecases/get_place_details.dart'
    show GetPlaceDetailsParams;
export '../../domain/usecases/get_current_location.dart'
    show GetCurrentLocationParams;

part 'location_providers.g.dart';

@Riverpod(keepAlive: true)
LocationRepository locationRepository(Ref ref) => LocationRepositoryImpl(
      remote: ref.watch(placesRemoteDataSourceProvider),
      device: ref.watch(deviceLocationDataSourceProvider),
    );

@riverpod
AutocompletePlaces autocompletePlacesUseCase(Ref ref) =>
    AutocompletePlaces(ref.watch(locationRepositoryProvider));

@riverpod
GetPlaceDetails getPlaceDetailsUseCase(Ref ref) =>
    GetPlaceDetails(ref.watch(locationRepositoryProvider));

@riverpod
GetCurrentLocation getCurrentLocationUseCase(Ref ref) =>
    GetCurrentLocation(ref.watch(locationRepositoryProvider));

@riverpod
GeocodeAddress geocodeAddressUseCase(Ref ref) =>
    GeocodeAddress(ref.watch(locationRepositoryProvider));
