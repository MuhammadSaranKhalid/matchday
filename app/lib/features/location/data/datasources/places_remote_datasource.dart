import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/error/exceptions.dart';
import '../models/geo_place_dto.dart';
import '../models/place_suggestion_dto.dart';

/// Talks to Google's HTTP geo endpoints: Places API (New) for autocomplete +
/// place details, and the Geocoding API for reverse-geocoding device GPS.
/// Returns DTOs and throws raw exceptions; the repository maps them to Failures.
class PlacesRemoteDataSource {
  PlacesRemoteDataSource({required String apiKey, http.Client? client})
      : _apiKey = apiKey,
        _client = client ?? http.Client();

  final String _apiKey;
  final http.Client _client;

  static final _autocompleteUri =
      Uri.parse('https://places.googleapis.com/v1/places:autocomplete');
  static const _detailsBase = 'https://places.googleapis.com/v1/places/';
  static const _geocodeBase =
      'https://maps.googleapis.com/maps/api/geocode/json';

  /// Type-ahead predictions. Uses `(regions)` so towns/villages/localities are
  /// included, biased (not restricted) to [regionCode] to stay global.
  Future<List<PlaceSuggestionDto>> autocomplete(
    String input, {
    required String sessionToken,
    String? languageCode,
    String? regionCode,
  }) async {
    _requireKey();
    final body = <String, dynamic>{
      'input': input,
      'includedPrimaryTypes': ['(regions)'],
      'sessionToken': sessionToken,
      if (languageCode != null) 'languageCode': languageCode,
      if (regionCode != null) 'regionCode': regionCode,
    };

    final res = await _client.post(
      _autocompleteUri,
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': _apiKey,
        'X-Goog-FieldMask':
            'suggestions.placePrediction.placeId,suggestions.placePrediction.text,suggestions.placePrediction.structuredFormat',
      },
      body: jsonEncode(body),
    );
    final json = _decode(res);

    final suggestions = (json['suggestions'] as List<dynamic>?) ?? const [];
    return suggestions
        .cast<Map<String, dynamic>>()
        .map(PlaceSuggestionDto.fromJson)
        .whereType<PlaceSuggestionDto>()
        .toList();
  }

  /// Resolves a picked suggestion to coordinates, closing the billing session.
  Future<GeoPlaceDto> placeDetails(
    String placeId, {
    required String sessionToken,
  }) async {
    _requireKey();
    final uri = Uri.parse('$_detailsBase$placeId').replace(
      queryParameters: {'sessionToken': sessionToken},
    );
    final res = await _client.get(
      uri,
      headers: {
        'X-Goog-Api-Key': _apiKey,
        'X-Goog-FieldMask': 'id,location,displayName,addressComponents',
      },
    );
    return GeoPlaceDto.fromDetailsJson(_decode(res));
  }

  /// Forward-geocodes typed text (e.g. "Mardan") to a place with coordinates.
  /// Permission-free — a plain HTTPS call. Throws [NotFoundException] when the
  /// text matches no place.
  Future<GeoPlaceDto> forwardGeocode(
    String address, {
    String? languageCode,
    String? regionCode,
  }) async {
    _requireKey();
    final uri = Uri.parse(_geocodeBase).replace(queryParameters: {
      'address': address,
      'key': _apiKey,
      if (languageCode != null) 'language': languageCode,
      if (regionCode != null) 'region': regionCode,
    });
    final res = await _client.get(uri);
    final json = _decode(res);

    final results = (json['results'] as List<dynamic>?) ?? const [];
    if (results.isEmpty) {
      throw NotFoundException('No place found for "$address"');
    }
    return GeoPlaceDto.fromGeocodeResult(results.first as Map<String, dynamic>);
  }

  /// Reverse-geocodes coordinates to a structured place — label + locality +
  /// district/province + postcode + ISO country. Returns null when the
  /// coordinates resolve to no named place (the caller still has the GPS
  /// lat/lng). `results` are ordered most-specific → least-specific; the first
  /// (street-level) result carries the richest components.
  Future<GeoPlaceDto?> reverseGeocode(
    double latitude,
    double longitude, {
    String? languageCode,
  }) async {
    _requireKey();
    final uri = Uri.parse(_geocodeBase).replace(queryParameters: {
      'latlng': '$latitude,$longitude',
      'key': _apiKey,
      if (languageCode != null) 'language': languageCode,
    });
    final res = await _client.get(uri);
    final json = _decode(res);

    final results = (json['results'] as List<dynamic>?) ?? const [];
    if (results.isEmpty) return null;
    return GeoPlaceDto.fromGeocodeResult(results.first as Map<String, dynamic>);
  }

  void _requireKey() {
    if (_apiKey.isEmpty) {
      throw const ServerException(
        'Missing GOOGLE_PLACES_API_KEY — pass it via --dart-define-from-file=dart_define.json',
      );
    }
  }

  /// Decodes a JSON body, turning non-200s into [ServerException]s carrying
  /// Google's error message when present.
  Map<String, dynamic> _decode(http.Response res) {
    final body = res.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      final message = (body['error'] as Map<String, dynamic>?)?['message'] ??
          body['error_message'] ??
          'Places request failed';
      throw ServerException(message.toString(), statusCode: res.statusCode);
    }
    // The Geocoding API returns 200 with a status field on logical errors.
    final status = body['status'] as String?;
    if (status != null && status != 'OK' && status != 'ZERO_RESULTS') {
      throw ServerException(
        body['error_message'] as String? ?? 'Geocoding failed: $status',
      );
    }
    return body;
  }
}
