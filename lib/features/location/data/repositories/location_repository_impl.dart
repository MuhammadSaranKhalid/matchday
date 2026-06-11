import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:http/http.dart' as http;

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/geo_place.dart';
import '../../domain/entities/place_suggestion.dart';
import '../../domain/repositories/location_repository.dart';
import '../datasources/device_location_datasource.dart';
import '../datasources/places_remote_datasource.dart';

class LocationRepositoryImpl implements LocationRepository {
  LocationRepositoryImpl({
    required PlacesRemoteDataSource remote,
    required DeviceLocationDataSource device,
  })  : _remote = remote,
        _device = device;

  final PlacesRemoteDataSource _remote;
  final DeviceLocationDataSource _device;

  @override
  Future<Either<Failure, List<PlaceSuggestion>>> autocomplete(
    String query, {
    required String sessionToken,
    String? languageCode,
    String? regionCode,
  }) async {
    try {
      final dtos = await _remote.autocomplete(
        query,
        sessionToken: sessionToken,
        languageCode: languageCode,
        regionCode: regionCode,
      );
      return Right(dtos.map((d) => d.toEntity()).toList());
    } catch (e) {
      return Left(_toFailure(e));
    }
  }

  @override
  Future<Either<Failure, GeoPlace>> placeDetails(
    String placeId, {
    required String sessionToken,
  }) async {
    try {
      final dto = await _remote.placeDetails(placeId, sessionToken: sessionToken);
      return Right(dto.toEntity(PlaceSource.places));
    } catch (e) {
      return Left(_toFailure(e));
    }
  }

  @override
  Future<Either<Failure, GeoPlace>> currentLocation({
    String? languageCode,
  }) async {
    try {
      final pos = await _device.currentPosition();
      final rg = await _remote.reverseGeocode(
        pos.latitude,
        pos.longitude,
        languageCode: languageCode,
      );
      return Right(GeoPlace(
        label: rg?.label ?? '',
        source: PlaceSource.gps,
        city: rg?.city,
        district: rg?.district,
        province: rg?.province,
        postcode: rg?.postcode,
        placeId: rg?.placeId,
        // Keep the device's own coordinates — more precise than the geocode's
        // snapped result point.
        latitude: pos.latitude,
        longitude: pos.longitude,
        countryCode: rg?.countryCode,
      ));
    } catch (e) {
      return Left(_toFailure(e));
    }
  }

  @override
  Future<Either<Failure, GeoPlace>> geocode(
    String query, {
    String? languageCode,
    String? regionCode,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return const Left(ValidationFailure('Enter a place to locate'));
    }
    try {
      final dto = await _remote.forwardGeocode(
        trimmed,
        languageCode: languageCode,
        regionCode: regionCode,
      );
      return Right(dto.toEntity(PlaceSource.geocoded));
    } catch (e) {
      return Left(_toFailure(e));
    }
  }

  Failure _toFailure(Object e) => switch (e) {
        PermissionException() => PermissionFailure(e.message),
        UnauthorizedException() => AuthFailure(e.message),
        NotFoundException() => NotFoundFailure(e.message),
        ServerException() => ServerFailure(e.message),
        SocketException() => const NetworkFailure(),
        http.ClientException() => const NetworkFailure(),
        _ => UnknownFailure(e.toString()),
      };
}
