import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/exceptions.dart';
import '../models/place_facet_dto.dart';
import '../models/team_dto.dart';
import '../models/team_member_dto.dart';
import '../models/team_search_result_dto.dart';
import '../models/unclaimed_player_dto.dart';

/// Talks to Supabase for the three teams tables. Returns DTOs, throws raw
/// exceptions. RLS scopes reads; client-generated UUIDs let offline creates
/// keep the same id after sync.
class TeamsRemoteDataSource {
  TeamsRemoteDataSource(this._supabase);
  final SupabaseClient _supabase;

  static const _teams = 'teams';
  static const _members = 'team_members';
  static const _unclaimed = 'unclaimed_players';

  String _requireUid() {
    final id = _supabase.auth.currentUser?.id;
    if (id == null) throw UnauthorizedException('Must be signed in');
    return id;
  }

  // ─── Pulls ───────────────────────────────────────────────────────────────

  Future<List<TeamDto>> listTeams() async {
    try {
      final rows = await _supabase.from(_teams).select();
      return rows.map(TeamDto.fromJson).toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<List<TeamMemberDto>> listMembers() async {
    try {
      final rows = await _supabase.from(_members).select();
      return rows.map(TeamMemberDto.fromJson).toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<List<UnclaimedPlayerDto>> listUnclaimed() async {
    try {
      final rows = await _supabase.from(_unclaimed).select();
      return rows.map(UnclaimedPlayerDto.fromJson).toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  /// Batch-fetches public profile metadata (display name, username, photo) for user IDs.
  Future<Map<String, Map<String, dynamic>>> getProfilesByIds(
      List<String> userIds) async {
    if (userIds.isEmpty) return {};
    try {
      final rows = await _supabase
          .from('profiles')
          .select('user_id, username, display_name, profile_photo_url')
          .filter('user_id', 'in', userIds);
      return {
        for (final r in (rows as List))
          r['user_id'] as String: r as Map<String, dynamic>,
      };
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  /// Batch-fetches unclaimed player records by unclaimed IDs.
  Future<Map<String, UnclaimedPlayerDto>> getUnclaimedByIds(
      List<String> unclaimedIds) async {
    if (unclaimedIds.isEmpty) return {};
    try {
      final rows = await _supabase
          .from(_unclaimed)
          .select()
          .filter('unclaimed_id', 'in', unclaimedIds);
      return {
        for (final r in (rows as List))
          r['unclaimed_id'] as String:
              UnclaimedPlayerDto.fromJson(r as Map<String, dynamic>),
      };
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  // ─── Writes ───────────────────────────────────────────────────────────────

  Future<TeamDto> createTeam(Map<String, dynamic> payload) async {
    try {
      final uid = _requireUid();
      final row = await _supabase
          .from(_teams)
          .insert({
            'team_id': payload['id'],
            'owner_id': uid,
            'managers': [uid],
            'team_name': payload['team_name'],
            'team_type': payload['team_type'],
            'privacy': payload['privacy'],
            if (payload['description'] != null)
              'description': payload['description'],
            if (payload['home_ground'] != null)
              'home_ground': payload['home_ground'],
            // Location jsonb: forward every structured geo field the caller
            // provides. Each is optional; null fields are omitted so the row
            // matches the §7 contract shape (docs/search-feature-design.md).
            // When lat/lng land, the generated `location_point` column auto-
            // populates and the GiST index picks the team up for proximity.
            'location': {
              if (payload['label'] != null) 'label': payload['label'],
              if (payload['city'] != null) 'city': payload['city'],
              if (payload['district'] != null) 'district': payload['district'],
              if (payload['province'] != null) 'province': payload['province'],
              if (payload['postcode'] != null) 'postcode': payload['postcode'],
              if (payload['place_id'] != null) 'place_id': payload['place_id'],
              if (payload['lat'] != null) 'lat': payload['lat'],
              if (payload['lng'] != null) 'lng': payload['lng'],
              if (payload['country_code'] != null)
                'country_code': payload['country_code'],
            },
            if (payload['founded_year'] != null)
              'founded_year': payload['founded_year'],
            'team_colors': {
              if (payload['primary_color'] != null)
                'primary': payload['primary_color'],
              if (payload['secondary_color'] != null)
                'secondary': payload['secondary_color'],
            },
            if (payload['tagline'] != null) 'tagline': payload['tagline'],
            if (payload['logo_monogram'] != null)
              'logo_monogram': payload['logo_monogram'],
          })
          .select()
          .single();
      return TeamDto.fromJson(row);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<TeamDto> updateTeam(String teamId, Map<String, dynamic> payload) async {
    try {
      _requireUid();
      final updates = <String, dynamic>{};
      if (payload.containsKey('team_name')) updates['team_name'] = payload['team_name'];
      if (payload.containsKey('team_type')) updates['team_type'] = payload['team_type'];
      if (payload.containsKey('privacy')) updates['privacy'] = payload['privacy'];
      if (payload.containsKey('description')) updates['description'] = payload['description'];
      if (payload.containsKey('home_ground')) updates['home_ground'] = payload['home_ground'];
      if (payload.containsKey('tagline')) updates['tagline'] = payload['tagline'];
      if (payload.containsKey('logo_monogram')) updates['logo_monogram'] = payload['logo_monogram'];
      if (payload.containsKey('founded_year')) updates['founded_year'] = payload['founded_year'];
      if (payload.containsKey('city') || payload.containsKey('district') || payload.containsKey('province')) {
        updates['location'] = {
          if (payload['city'] != null) 'city': payload['city'],
          if (payload['district'] != null) 'district': payload['district'],
          if (payload['province'] != null) 'province': payload['province'],
          if (payload['postcode'] != null) 'postcode': payload['postcode'],
          if (payload['country_code'] != null) 'country_code': payload['country_code'],
        };
      }
      if (payload.containsKey('primary_color') || payload.containsKey('secondary_color')) {
        updates['team_colors'] = {
          if (payload['primary_color'] != null) 'primary': payload['primary_color'],
          if (payload['secondary_color'] != null) 'secondary': payload['secondary_color'],
        };
      }

      final row = await _supabase
          .from(_teams)
          .update(updates)
          .eq('team_id', teamId)
          .select()
          .single();
      return TeamDto.fromJson(row);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  /// Uploads [bytes] to `team-logos/<teamId>/logo.<ext>` and patches the
  /// team row's `logo_url`. Returns the public URL. Mirrors the avatar
  /// upload pattern in `onboarding_remote_datasource.dart`.
  Future<String> uploadTeamLogo({
    required String teamId,
    required List<int> bytes,
    required String extension,
  }) async {
    try {
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
      // Cache-bust so a replacement upload shows immediately at the same URL.
      final cacheBusted = '$url?v=${DateTime.now().millisecondsSinceEpoch}';
      await _supabase
          .from(_teams)
          .update({'logo_url': cacheBusted})
          .eq('team_id', teamId);
      return cacheBusted;
    } on StorageException catch (e) {
      throw ServerException(e.message);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  String _normalizeExtension(String raw) {
    final stripped = raw.startsWith('.') ? raw.substring(1) : raw;
    switch (stripped.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'jpg';
      case 'png':
        return 'png';
      case 'webp':
        return 'webp';
      default:
        return 'jpg';
    }
  }

  String _contentTypeFor(String ext) {
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'jpg':
      default:
        return 'image/jpeg';
    }
  }

  Future<UnclaimedPlayerDto> createUnclaimed(
      Map<String, dynamic> payload) async {
    try {
      final row = await _supabase
          .from(_unclaimed)
          .insert({
            'unclaimed_id': payload['id'],
            'display_name': payload['display_name'],
            if (payload['phone_number'] != null)
              'phone_number': payload['phone_number'],
            if (payload['player_profile'] != null)
              'player_profile': payload['player_profile'],
            'added_by': _requireUid(),
          })
          .select()
          .single();
      return UnclaimedPlayerDto.fromJson(row);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  /// Searches registered Matchday users by username or display name.
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      if (query.trim().isEmpty) return [];
      final clean = query.trim().replaceAll('@', '');
      final rows = await _supabase
          .from('profiles')
          .select('user_id, username, display_name, profile_photo_url, player_profiles(player_role)')
          .or('username.ilike.%$clean%,display_name.ilike.%$clean%')
          .limit(20);
      return (rows as List).cast<Map<String, dynamic>>();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<TeamMemberDto> createMember(Map<String, dynamic> payload) async {
    try {
      // Polymorphic player ref: the table has user_id XOR unclaimed_id, no
      // player_id/player_type columns. Caller still speaks the domain
      // vocabulary (player_id + player_type) — split it here at the wire
      // boundary.
      final playerType = payload['player_type'] as String;
      final playerId = payload['player_id'] as String;
      final row = await _supabase
          .from(_members)
          .insert({
            'membership_id': payload['id'],
            'team_id': payload['team_id'],
            if (playerType == 'claimed') 'user_id': playerId,
            if (playerType == 'unclaimed') 'unclaimed_id': playerId,
            'role': payload['role'],
            if (payload['jersey_number'] != null)
              'jersey_number': payload['jersey_number'],
            'added_by': _requireUid(),
          })
          .select()
          .single();
      return TeamMemberDto.fromJson(row);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<TeamMemberDto> updateMember(
    String id,
    Map<String, dynamic> changes,
  ) async {
    try {
      final row = await _supabase
          .from(_members)
          .update(changes)
          .eq('membership_id', id)
          .select()
          .single();
      return TeamMemberDto.fromJson(row);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw ServerException('That jersey number is already taken');
      }
      throw ServerException(e.message);
    }
  }

  Future<void> deleteMember(String id) async {
    try {
      await _supabase.from(_members).delete().eq('membership_id', id);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  // ─── Search (edge functions) ───────────────────────────────────────────────

  /// Calls `search-teams`. The function selects a behavioural mode from which
  /// inputs are non-null — see docs/search-feature-design.md §9.1.
  /// `radiusKm`/`scaleKm`/`countryCode`/`limit` are all server-defaulted; pass
  /// null to use the server defaults.
  Future<List<TeamSearchResultDto>> searchTeams({
    String? query,
    double? lat,
    double? lng,
    double? radiusKm,
    double? scaleKm,
    String? countryCode,
    int? limit,
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
      );
      final data = res.data;
      if (data is! Map || data['results'] is! List) {
        throw ServerException('Unexpected search-teams payload');
      }
      final rows = (data['results'] as List).cast<Map<String, dynamic>>();
      return rows.map(TeamSearchResultDto.fromJson).toList();
    } on FunctionException catch (e) {
      throw ServerException('search-teams failed: ${e.details ?? e.reasonPhrase ?? ''}');
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  /// Calls `team-place-facets`. Returns the top cities by team count for the
  /// current country (defaulted to the caller's profile country when
  /// [countryCode] is null).
  Future<List<PlaceFacetDto>> teamPlaceFacets({String? countryCode}) async {
    try {
      final res = await _supabase.functions.invoke(
        'team-place-facets',
        body: {
          if (countryCode != null) 'countryCode': countryCode,
        },
      );
      final data = res.data;
      if (data is! Map || data['facets'] is! List) {
        throw ServerException('Unexpected team-place-facets payload');
      }
      final rows = (data['facets'] as List).cast<Map<String, dynamic>>();
      return rows.map(PlaceFacetDto.fromJson).toList();
    } on FunctionException catch (e) {
      throw ServerException('team-place-facets failed: ${e.details ?? e.reasonPhrase ?? ''}');
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  // ─── Team Invites & Claim Requests ────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getTeamInvites(String teamId) async {
    try {
      final rows = await _supabase
          .from('team_invites')
          .select('*, invitee:profiles!invitee_id(display_name, username, profile_photo_url)')
          .eq('team_id', teamId)
          .eq('status', 'pending')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(rows);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<void> cancelTeamInvite(String inviteId) async {
    try {
      await _supabase
          .from('team_invites')
          .update({'status': 'cancelled'})
          .eq('invite_id', inviteId);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }
  Future<void> sendTeamInvite({
    required String teamId,
    required String inviteeId,
    String? message,
    String? role,
    int? jerseyNumber,
  }) async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) throw ServerException('Not authenticated');
    try {
      await _supabase.from('team_invites').insert({
        'team_id': teamId,
        'invitee_id': inviteeId,
        'invited_by': uid,
        if (message != null && message.trim().isNotEmpty) 'message': message.trim(),
        if (role != null) 'role': role,
        if (jerseyNumber != null) 'jersey_number': jerseyNumber,
        'status': 'pending',
      });
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<void> sendClaimRequest({
    required String unclaimedId,
    String? message,
  }) async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) throw ServerException('Not authenticated');
    try {
      await _supabase.from('claim_requests').insert({
        'unclaimed_id': unclaimedId,
        'requester_id': uid,
        if (message != null && message.trim().isNotEmpty) 'message': message.trim(),
        'status': 'pending',
      });
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<List<Map<String, dynamic>>> getClaimRequests(String teamId) async {
    try {
      final members = await _supabase
          .from('team_members')
          .select('unclaimed_id')
          .eq('team_id', teamId)
          .not('unclaimed_id', 'is', null)
          .eq('status', 'active');
      final unclaimedIds = members
          .map((m) => m['unclaimed_id'] as String?)
          .whereType<String>()
          .toList();
      if (unclaimedIds.isEmpty) return [];

      final rows = await _supabase
          .from('claim_requests')
          .select('*, requester:profiles!requester_id(display_name, username, profile_photo_url), unclaimed:unclaimed_players!unclaimed_id(display_name, phone_number)')
          .inFilter('unclaimed_id', unclaimedIds)
          .eq('status', 'pending')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(rows);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<void> approveClaimRequest(String requestId) async {
    try {
      await _supabase.rpc<void>('approve_claim_request', params: {'p_request_id': requestId});
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<void> rejectClaimRequest(String requestId) async {
    try {
      await _supabase
          .from('claim_requests')
          .update({
            'status': 'rejected',
            'decided_by': _requireUid(),
            'decided_at': DateTime.now().toIso8601String(),
          })
          .eq('request_id', requestId);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<List<Map<String, dynamic>>> getTeamJoinRequests(String teamId) async {
    try {
      final rows = await _supabase
          .from('team_join_requests')
          .select('*, player:profiles!player_id(display_name, username, profile_photo_url)')
          .eq('team_id', teamId)
          .eq('status', 'pending')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(rows);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<void> acceptTeamJoinRequest(String requestId, {int? jerseyNumber}) async {
    try {
      await _supabase.rpc<dynamic>('accept_team_join_request', params: {
        'p_request_id': requestId,
        if (jerseyNumber != null) 'p_jersey_number': jerseyNumber,
      });
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<void> declineTeamJoinRequest(String requestId) async {
    try {
      await _supabase.rpc<void>('decline_team_join_request', params: {
        'p_request_id': requestId,
      });
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<void> requestToJoinTeam(String teamId, {String role = 'player', String? message}) async {
    try {
      await _supabase.rpc<dynamic>('request_to_join_team', params: {
        'p_team_id': teamId,
        'p_role': role,
        if (message != null && message.isNotEmpty) 'p_message': message,
      });
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  // ─── Realtime ──────────────────────────────────────────────────────────────

  Stream<List<TeamDto>> watchTeams() => _supabase
      .from(_teams)
      .stream(primaryKey: ['team_id']).map((r) => r.map(TeamDto.fromJson).toList());

  Stream<List<TeamMemberDto>> watchMembers() => _supabase
      .from(_members)
      .stream(primaryKey: ['membership_id'])
      .map((r) => r.map(TeamMemberDto.fromJson).toList());

  Stream<List<UnclaimedPlayerDto>> watchUnclaimed() => _supabase
      .from(_unclaimed)
      .stream(primaryKey: ['unclaimed_id'])
      .map((r) => r.map(UnclaimedPlayerDto.fromJson).toList());
}
