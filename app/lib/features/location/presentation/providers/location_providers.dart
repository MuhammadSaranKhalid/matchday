import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/datasources/location_datasource_providers.dart';
import '../../data/repositories/location_repository_impl.dart';
import '../../domain/repositories/location_repository.dart';

part 'location_providers.g.dart';

@Riverpod(keepAlive: true)
LocationRepository locationRepository(Ref ref) => LocationRepositoryImpl(
      remote: ref.watch(placesRemoteDataSourceProvider),
      device: ref.watch(deviceLocationDataSourceProvider),
    );
