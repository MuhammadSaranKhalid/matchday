import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../datasources/device_location_datasource.dart';
import '../datasources/places_remote_datasource.dart';

part 'location_datasource_providers.g.dart';

/// Compile-time Places key. Pass via --dart-define-from-file=dart_define.json.
/// Empty in a misconfigured build; the data source throws a clear error then.
const _placesApiKey = String.fromEnvironment('GOOGLE_PLACES_API_KEY');

@Riverpod(keepAlive: true)
PlacesRemoteDataSource placesRemoteDataSource(Ref ref) =>
    PlacesRemoteDataSource(apiKey: _placesApiKey);

@Riverpod(keepAlive: true)
DeviceLocationDataSource deviceLocationDataSource(Ref ref) =>
    const DeviceLocationDataSource();
