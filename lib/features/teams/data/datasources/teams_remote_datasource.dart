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

  /// Every unclaimed_players column the API roles may read.
  ///
  /// `phone_number` and `email` are revoked at column level (see
  /// 20260101000120_unclaimed_players.sql): they are contact details for
  /// people who never signed up. A bare `.select()` expands to `select *`,
  /// which Postgres rejects outright once any column is revoked — so every
  /// read of this table must name its columns. A manager who needs the phone
  /// number calls unclaimed_player_contact_for_manager().
  static const _unclaimedCols =
      'unclaimed_id, display_name, added_by, player_profile, '
      'claimed_by_user_id, claimed_at, created_at, updated_at';

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

  /// One-shot roster read. Roles live in `team_member_roles` since
  /// 2026-09-11, so they are embedded here — a plain `select()` would return
  /// members who appear to hold nothing.
  Future<List<TeamMemberDto>> listMembers() async {
    try {
      final rows = await _supabase
          .from(_members)
          .select('*, team_member_roles(role_key)');
      return rows.map(TeamMemberDto.fromJson).toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<List<UnclaimedPlayerDto>> listUnclaimed() async {
    try {
      final rows = await _supabase.from(_unclaimed).select(_unclaimedCols);
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
          .select(_unclaimedCols)
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
      _requireUid();
      // Team writes are RPC-only. The server derives ownership from auth.uid()
      // and creates the owner staff assignment atomically with the team.
      final row = await _supabase.rpc<Map<String, dynamic>>('create_team', params: {
        'p_team_id': payload['id'],
        'p_team_name': payload['team_name'],
        'p_team_type': payload['team_type'],
        'p_privacy': payload['privacy'],
        'p_details': {
          for (final key in ['description', 'home_ground', 'tagline',
            'logo_monogram', 'founded_year'])
            if (payload[key] != null) key: payload[key],
          'location': {
            for (final key in ['label', 'city', 'district', 'province',
              'postcode', 'place_id', 'lat', 'lng', 'country_code'])
              if (payload[key] != null) key: payload[key],
          },
          'team_colors': {
            if (payload['primary_color'] != null) 'primary': payload['primary_color'],
            if (payload['secondary_color'] != null) 'secondary': payload['secondary_color'],
            if (payload['crest_kind'] != null) 'crest_kind': payload['crest_kind'],
          },
        },
      });
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
      if (payload.containsKey('status')) updates['status'] = payload['status'];
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

      // Preserve logo style and resolved location metadata when editing only
      // one color or location field. The profile RPC replaces each JSON object.
      if (updates.containsKey('team_colors') || updates.containsKey('location')) {
        final current = await _supabase.from(_teams)
            .select('team_colors, location').eq('team_id', teamId).single();
        for (final key in ['team_colors', 'location']) {
          if (updates.containsKey(key)) {
            updates[key] = {
              ...?current[key] as Map<String, dynamic>?,
              ...updates[key] as Map<String, dynamic>,
            };
          }
        }
      }
      final row = await _supabase.rpc<Map<String, dynamic>>(
        'update_team_profile',
        params: {'p_team_id': teamId, 'p_patch': updates},
      );
      return TeamDto.fromJson(row);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  /// Self-leave. Direct deletes/updates on one's own `team_members` row are
  /// denied by RLS (a player could otherwise promote themselves), so the
  /// server exposes `leave_team()` as the only path — SECURITY DEFINER, and
  /// it constrains the write to `status='inactive' + left_at=now()`.
  Future<void> leaveTeam(String membershipId) async {
    try {
      _requireUid();
      await _supabase.rpc<void>(
        'leave_team',
        params: {'p_membership_id': membershipId},
      );
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  /// Promotes or demotes a teammate. Direct UPDATE of `team_members.role` is
  /// blocked by the `team_members_guard_role` trigger — `role` is a privilege
  /// now, and the manager-edit policy that exists for jersey numbers would
  /// otherwise let any manager promote themselves to owner.
  ///
  /// The RPC enforces "you may never act on, or grant, a rung at or above your
  /// own" and swaps the captaincy atomically when promoting to captain.
  /// A `42501` means the caller's rung is too low; surface it as an
  /// [UnauthorizedException] so the repository can map it to an AuthFailure.
  Future<void> setMemberRole(String membershipId, String role) async {
    try {
      _requireUid();
      await _supabase.rpc<void>(
        'set_team_member_role',
        params: {'p_membership_id': membershipId, 'p_new_role': role},
      );
    } on PostgrestException catch (e) {
      if (e.code == '42501') throw UnauthorizedException(e.message);
      if (e.code == 'P0002') throw NotFoundException(e.message);
      throw ServerException(e.message);
    }
  }

  /// Hands the team to another active member. Owner-only; swaps
  /// the `owner` role between two membership rows in one transaction.
/// (`teams.owner_id` is gone; `created_by` is history, not authority.)
  Future<void> transferOwnership(String teamId, String newOwnerId) async {
    try {
      _requireUid();
      await _supabase.rpc<void>(
        'transfer_team_ownership',
        params: {'p_team_id': teamId, 'p_new_owner_id': newOwnerId},
      );
    } on PostgrestException catch (e) {
      if (e.code == '42501') throw UnauthorizedException(e.message);
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
      await _supabase.rpc<void>('update_team_profile', params: {
        'p_team_id': teamId,
        'p_patch': {'logo_url': cacheBusted},
      });
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

  /// Creates the player and membership atomically through the manager-only API.
  /// Production intentionally disallows direct inserts into both tables.
  Future<void> addUnclaimedTeamMember({
    required String teamId,
    required String displayName,
    String? phoneNumber,
    int? jerseyNumber,
    Map<String, dynamic> playerProfile = const {},
  }) async {
    try {
      _requireUid();
      await _supabase.rpc<String>('add_unclaimed_team_member', params: {
        'p_team_id': teamId,
        'p_display_name': displayName,
        'p_phone_number': phoneNumber,
        'p_jersey_number': jerseyNumber,
        'p_player_profile': playerProfile,
      });
    } on PostgrestException catch (e) {
      if (e.code == '42501' &&
          e.message == 'Only team staff can add players') {
        throw UnauthorizedException(e.message);
      }
      if (e.code == '23505' &&
          e.message.contains('team_members_unique_jersey')) {
        throw ServerException('That jersey number is already taken');
      }
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

      // `phone_number` is deliberately absent from this embed. It is revoked
      // from anon/authenticated at column level (unclaimed_players holds
      // contact details for people who never signed up), so selecting it here
      // makes PostgREST reject the whole query. A manager who needs the number
      // fetches it per-row through unclaimed_player_contact_for_manager(),
      // which re-checks that they manage a team the placeholder plays for.
      final rows = await _supabase
          .from('claim_requests')
          .select(
            '*, requester:profiles!requester_id(display_name, username, profile_photo_url), '
            'unclaimed:unclaimed_players!unclaimed_id(display_name)',
          )
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

  /// Roles, as their own realtime stream keyed by membership.
  ///
  /// A Supabase realtime stream CANNOT join — it replays single-table row
  /// sets — so the embedded `team_member_roles(role_key)` trick that works for
  /// [listMembers] is unavailable here. Roles therefore arrive separately and
  /// are combined in the repository, the same shape `watchMyTeams` already
  /// uses for teams + members.
  Stream<Map<String, Set<String>>> watchMemberRoles() => _supabase
      .from('team_member_roles')
      .stream(primaryKey: ['membership_id', 'scope', 'role_key'])
      .map((rows) {
        final byMembership = <String, Set<String>>{};
        for (final r in rows) {
          final mid = r['membership_id'] as String?;
          final key = r['role_key'] as String?;
          if (mid == null || key == null) continue;
          (byMembership[mid] ??= <String>{}).add(key);
        }
        return byMembership;
      });

  // watchUnclaimed() was removed 2026-09-06. It had no callers, and a realtime
  // stream replays the whole row — including the phone_number / email columns
  // now revoked from the API roles.
}
