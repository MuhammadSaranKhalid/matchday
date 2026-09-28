import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../models/place_facet_dto.dart';
import '../models/team_dto.dart';
import '../models/team_search_result_dto.dart';

/// One-shot datasource for team profile/discovery data only.
///
/// Membership and roster concerns deliberately live in
/// [TeamMembershipRemoteDataSource].
class TeamsRemoteDataSource {
  TeamsRemoteDataSource(this._supabase);

  final SupabaseClient _supabase;

  static const _teams = 'teams';

  static const _teamSelect = '''
    team_id,
    created_by,
    team_name,
    team_type,
    tagline,
    logo_url,
    logo_monogram,
    team_colors,
    description,
    home_ground,
    founded_year,
    is_verified,
    privacy,
    status,
    max_squad_size,
    created_at,
    updated_at
  ''';

  String _requireUid() {
    final id = _supabase.auth.currentUser?.id;
    if (id == null) throw const UnauthorizedException('Must be signed in');
    return id;
  }

  Future<TeamDto?> getTeam(String teamId) async {
    try {
      final row = await _supabase
          .from(_teams)
          .select(_teamSelect)
          .eq('team_id', teamId)
          .maybeSingle();
      return row == null ? null : TeamDto.fromJson(row);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<List<TeamDto>> getTeamsByIds(List<String> teamIds) async {
    if (teamIds.isEmpty) return const [];
    try {
      final rows = await _supabase
          .from(_teams)
          .select(_teamSelect)
          .inFilter('team_id', teamIds);
      return rows.map(TeamDto.fromJson).toList(growable: false);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<TeamDto> createTeam(Map<String, dynamic> payload) async {
    try {
      final uid = _requireUid();
      final row = await _supabase
          .from(_teams)
          .insert({
            'team_id': payload['id'],
            'created_by': uid,
            'team_name': payload['team_name'],
            'team_type': payload['team_type'],
            'privacy': payload['privacy'] ?? 'public',
            if (payload['description'] != null)
              'description': payload['description'],
            if (payload['home_ground'] != null)
              'home_ground': payload['home_ground'],
            if (payload['tagline'] != null) 'tagline': payload['tagline'],
            if (payload['logo_monogram'] != null)
              'logo_monogram': payload['logo_monogram'],
            if (payload['founded_year'] != null)
              'founded_year': payload['founded_year'],
            'team_colors': {
              if (payload['primary_color'] != null)
                'primary': payload['primary_color'],
              if (payload['secondary_color'] != null)
                'secondary': payload['secondary_color'],
              if (payload['crest_kind'] != null)
                'crest_kind': payload['crest_kind'],
            },
          })
          .select(_teamSelect)
          .single();
      return TeamDto.fromJson(row);
    } on PostgrestException catch (e) {
      if (e.code == '42501') throw UnauthorizedException(e.message);
      throw ServerException(e.message);
    }
  }

  Future<TeamDto> updateTeam(
    String teamId,
    Map<String, dynamic> payload,
  ) async {
    try {
      _requireUid();
      final updates = <String, dynamic>{};
      for (final key in [
        'team_name',
        'team_type',
        'privacy',
        'description',
        'home_ground',
        'tagline',
        'logo_monogram',
        'founded_year',
      ]) {
        if (payload.containsKey(key)) updates[key] = payload[key];
      }

      if (payload.containsKey('primary_color') ||
          payload.containsKey('secondary_color')) {
        final current = await _supabase
            .from(_teams)
            .select('team_colors')
            .eq('team_id', teamId)
            .single();
        updates['team_colors'] = {
          ...?current['team_colors'] as Map<String, dynamic>?,
          if (payload.containsKey('primary_color'))
            'primary': payload['primary_color'],
          if (payload.containsKey('secondary_color'))
            'secondary': payload['secondary_color'],
        };
      }

      final row = await _supabase
          .from(_teams)
          .update(updates)
          .eq('team_id', teamId)
          .select(_teamSelect)
          .single();
      return TeamDto.fromJson(row);
    } on PostgrestException catch (e) {
      if (e.code == '42501') throw UnauthorizedException(e.message);
      throw ServerException(e.message);
    }
  }

  Future<void> setTeamStatus(String teamId, String status) async {
    try {
      _requireUid();
      await _supabase.rpc<dynamic>(
        'set_team_status',
        params: {'p_team_id': teamId, 'p_status': status},
      );
    } on PostgrestException catch (e) {
      if (e.code == '42501' || e.code == '28000') {
        throw UnauthorizedException(e.message);
      }
      if (e.code == 'P0002') throw NotFoundException(e.message);
      throw ServerException(e.message);
    }
  }

  Future<String> uploadTeamLogo({
    required String teamId,
    required List<int> bytes,
    required String extension,
  }) async {
    try {
      _requireUid();
      final ext = _normalizeExtension(extension);
      final path = '$teamId/logo.$ext';
      await _supabase.storage.from('team-logos').uploadBinary(
            path,
            Uint8List.fromList(bytes),
            fileOptions: FileOptions(
              contentType: _contentTypeFor(ext),
              upsert: true,
            ),
          );
      final url = _supabase.storage.from('team-logos').getPublicUrl(path);
      final cacheBusted = '$url?v=${DateTime.now().millisecondsSinceEpoch}';
      await _supabase
          .from(_teams)
          .update({'logo_url': cacheBusted})
          .eq('team_id', teamId);
      return cacheBusted;
    } on StorageException catch (e) {
      throw ServerException(e.message);
    } on PostgrestException catch (e) {
      if (e.code == '42501') throw UnauthorizedException(e.message);
      throw ServerException(e.message);
    }
  }

  Future<List<TeamSearchResultDto>> searchTeams({
    String? query,
    double? lat,
    double? lng,
    double? radiusKm,
    double? scaleKm,
    String? countryCode,
    int? limit,
    Future<void>? cancelSignal,
  }) async {
    try {
      final res = await _supabase.functions.invoke(
        'search-teams',
        body: {
          if (query != null && query.isNotEmpty) 'q': query,
          if (lat != null) 'lat': lat,
          if (lng != null) 'lng': lng,
          if (radiusKm != null) 'radiusKm': radiusKm,
          if (scaleKm != null) 'scaleKm': scaleKm,
          if (countryCode != null) 'countryCode': countryCode,
          if (limit != null) 'limit': limit,
        },
        abortSignal: cancelSignal,
      );
      final data = res.data;
      if (data is! Map || data['results'] is! List) {
        throw const ServerException('Unexpected search-teams payload');
      }
      return (data['results'] as List)
          .cast<Map<String, dynamic>>()
          .map(TeamSearchResultDto.fromJson)
          .toList(growable: false);
    } on RequestAbortedException {
      throw const OperationCancelledException();
    } on FunctionsHttpException catch (e) {
      throw ServerException(
        'search-teams HTTP error (${e.status}): '
        '${e.details ?? e.reasonPhrase ?? ''}',
        statusCode: e.status,
      );
    } on FunctionsFetchException catch (e) {
      throw NetworkException(
        e.reasonPhrase ?? 'Failed to reach team search service',
      );
    } on FunctionsRelayException catch (e) {
      throw ServerException(
        'search-teams relay failure: ${e.reasonPhrase ?? ''}',
        statusCode: e.status,
      );
    } on FunctionException catch (e) {
      throw ServerException(
        'search-teams failed: ${e.details ?? e.reasonPhrase ?? ''}',
      );
    }
  }

  Future<List<PlaceFacetDto>> teamPlaceFacets({
    String? countryCode,
    Future<void>? cancelSignal,
  }) async {
    try {
      final res = await _supabase.functions.invoke(
        'team-place-facets',
        body: {if (countryCode != null) 'countryCode': countryCode},
        abortSignal: cancelSignal,
      );
      final data = res.data;
      if (data is! Map || data['facets'] is! List) {
        throw const ServerException('Unexpected team-place-facets payload');
      }
      return (data['facets'] as List)
          .cast<Map<String, dynamic>>()
          .map(PlaceFacetDto.fromJson)
          .toList(growable: false);
    } on RequestAbortedException {
      throw const OperationCancelledException();
    } on FunctionsHttpException catch (e) {
      throw ServerException(
        'team-place-facets HTTP error (${e.status}): '
        '${e.details ?? e.reasonPhrase ?? ''}',
        statusCode: e.status,
      );
    } on FunctionsFetchException catch (e) {
      throw NetworkException(
        e.reasonPhrase ?? 'Failed to reach team facets service',
      );
    } on FunctionsRelayException catch (e) {
      throw ServerException(
        'team-place-facets relay failure: ${e.reasonPhrase ?? ''}',
        statusCode: e.status,
      );
    } on FunctionException catch (e) {
      throw ServerException(
        'team-place-facets failed: ${e.details ?? e.reasonPhrase ?? ''}',
      );
    }
  }

  String _normalizeExtension(String raw) {
    final stripped = raw.startsWith('.') ? raw.substring(1) : raw;
    return switch (stripped.toLowerCase()) {
      'png' => 'png',
      'webp' => 'webp',
      _ => 'jpg',
    };
  }

  String _contentTypeFor(String ext) => switch (ext) {
        'png' => 'image/png',
        'webp' => 'image/webp',
        _ => 'image/jpeg',
      };
}
