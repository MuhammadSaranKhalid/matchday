import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../models/team_dto.dart';
import '../models/team_member_dto.dart';

typedef TeamMembershipRecord = ({TeamMemberDto member, TeamDto team});

typedef TeamRosterRecord =
    ({
      TeamMemberDto member,
      Map<String, dynamic>? profile,
      Map<String, dynamic>? unclaimed,
    });

/// One-shot Supabase source for team membership, roster and membership
/// workflows. No Postgres Changes stream is kept open by this feature.
class TeamMembershipRemoteDataSource {
  TeamMembershipRemoteDataSource(this._supabase);

  final SupabaseClient _supabase;

  static const _readTimeout = Duration(seconds: 12);

  static const _membershipSelect = '''
    membership_id,
    team_id,
    user_id,
    unclaimed_id,
    jersey_number,
    added_by,
    joined_at,
    updated_at,
    team_member_roles(role_key),
    team:teams!team_members_team_id_fkey(
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
    )
  ''';

  static const _rosterMembershipSelect = '''
    membership_id,
    team_id,
    user_id,
    unclaimed_id,
    jersey_number,
    added_by,
    joined_at,
    updated_at
  ''';

  String _requireUid() {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) throw const UnauthorizedException('Must be signed in');
    return uid;
  }

  Future<List<TeamMembershipRecord>> getCurrentUserMemberships() async {
    final uid = _requireUid();
    try {
      final rows = await _supabase
          .from('team_members')
          .select(_membershipSelect)
          .eq('user_id', uid)
          .eq('status', 'active')
          .order('joined_at')
          .timeout(_readTimeout);

      return rows.map(_membershipFromRow).toList(growable: false);
    } on TimeoutException {
      throw const ServerException('Team memberships request timed out.');
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<List<TeamMembershipRecord>> getUserMemberships(String userId) async {
    if (userId.trim().isEmpty) return const [];
    try {
      final rows = await _supabase
          .from('team_members')
          .select(_membershipSelect)
          .eq('user_id', userId)
          .eq('status', 'active')
          .order('joined_at')
          .timeout(_readTimeout);
      return rows.map(_membershipFromRow).toList(growable: false);
    } on TimeoutException {
      throw const ServerException('User team memberships request timed out.');
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<TeamMembershipRecord?> getCurrentUserMembershipForTeam(
    String teamId,
  ) async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return null;
    try {
      final row = await _supabase
          .from('team_members')
          .select(_membershipSelect)
          .eq('team_id', teamId)
          .eq('user_id', uid)
          .eq('status', 'active')
          .maybeSingle()
          .timeout(_readTimeout);
      return row == null ? null : _membershipFromRow(row);
    } on TimeoutException {
      throw const ServerException('Team membership request timed out.');
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  TeamMembershipRecord _membershipFromRow(Map<String, dynamic> row) {
    final teamJson = row['team'];
    if (teamJson is! Map) {
      throw const ServerException('Active membership is missing its team record');
    }
    return (
      member: TeamMemberDto.fromJson(Map<String, dynamic>.from(row)),
      team: TeamDto.fromJson(Map<String, dynamic>.from(teamJson)),
    );
  }

  Future<List<TeamRosterRecord>> getRoster(String teamId) async {
    try {
      final memberRows = await _supabase
          .from('team_members')
          .select(_rosterMembershipSelect)
          .eq('team_id', teamId)
          .eq('status', 'active')
          .order('joined_at')
          .timeout(_readTimeout);

      if (memberRows.isEmpty) return const [];

      final membershipIds = memberRows
          .map((row) => row['membership_id'] as String)
          .toList(growable: false);

      final roleRows = await _supabase
          .from('team_member_roles')
          .select('membership_id, role_key')
          .eq('team_id', teamId)
          .inFilter('membership_id', membershipIds)
          .timeout(_readTimeout);

      final rolesByMembership = <String, List<Map<String, dynamic>>>{};
      for (final row in roleRows) {
        final membershipId = row['membership_id'] as String?;
        final roleKey = row['role_key'] as String?;
        if (membershipId == null || roleKey == null) continue;
        (rolesByMembership[membershipId] ??= <Map<String, dynamic>>[]).add({
          'role_key': roleKey,
        });
      }

      final members = memberRows
          .map((row) {
            final json = Map<String, dynamic>.from(row);
            final membershipId = json['membership_id'] as String;
            json['team_member_roles'] =
                rolesByMembership[membershipId] ??
                const <Map<String, dynamic>>[];
            return TeamMemberDto.fromJson(json);
          })
          .toList(growable: false);

      final userIds = members
          .map((member) => member.userId)
          .whereType<String>()
          .toSet()
          .toList(growable: false);
      final unclaimedIds = members
          .map((member) => member.unclaimedId)
          .whereType<String>()
          .toSet()
          .toList(growable: false);

      final profiles = <String, Map<String, dynamic>>{};
      if (userIds.isNotEmpty) {
        final profileRows = await _supabase
            .from('profiles')
            .select('user_id, username, display_name, profile_photo_url')
            .inFilter('user_id', userIds)
            .timeout(_readTimeout);
        for (final row in profileRows) {
          final id = row['user_id'] as String?;
          if (id != null) profiles[id] = Map<String, dynamic>.from(row);
        }
      }

      final unclaimed = <String, Map<String, dynamic>>{};
      if (unclaimedIds.isNotEmpty) {
        final rows = await _supabase
            .from('unclaimed_players')
            .select('unclaimed_id, display_name')
            .inFilter('unclaimed_id', unclaimedIds)
            .timeout(_readTimeout);
        for (final row in rows) {
          final id = row['unclaimed_id'] as String?;
          if (id != null) unclaimed[id] = Map<String, dynamic>.from(row);
        }
      }

      return [
        for (final member in members)
          (
            member: member,
            profile: member.userId == null ? null : profiles[member.userId],
            unclaimed:
                member.unclaimedId == null
                    ? null
                    : unclaimed[member.unclaimedId],
          ),
      ];
    } on TimeoutException {
      throw const ServerException(
        'Roster request timed out. Pull to refresh and try again.',
      );
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<Map<String, dynamic>?> getMyPendingInviteForTeam(String teamId) async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return null;
    try {
      return await _supabase
          .from('team_invites')
          .select('''
            invite_id,
            team_id,
            invitee_id,
            invited_by,
            message,
            role,
            jersey_number,
            status,
            created_at,
            inviter:profiles!invited_by(display_name, username)
          ''')
          .eq('team_id', teamId)
          .eq('invitee_id', uid)
          .eq('status', 'pending')
          .maybeSingle()
          .timeout(_readTimeout);
    } on TimeoutException {
      throw const ServerException('Invite request timed out.');
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<List<Map<String, dynamic>>> getTeamPendingInvites(
    String teamId,
  ) async {
    try {
      final rows = await _supabase
          .from('team_invites')
          .select('''
            *,
            invitee:profiles!invitee_id(
              display_name,
              username,
              profile_photo_url
            )
          ''')
          .eq('team_id', teamId)
          .eq('status', 'pending')
          .order('created_at', ascending: false)
          .timeout(_readTimeout);
      return List<Map<String, dynamic>>.from(rows);
    } on TimeoutException {
      throw const ServerException('Invitations request timed out.');
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<List<Map<String, dynamic>>> getTeamPendingJoinRequests(
    String teamId,
  ) async {
    try {
      final rows = await _supabase
          .from('team_join_requests')
          .select('''
            *,
            player:profiles!player_id(
              display_name,
              username,
              profile_photo_url
            )
          ''')
          .eq('team_id', teamId)
          .eq('status', 'pending')
          .order('created_at', ascending: false)
          .timeout(_readTimeout);
      return List<Map<String, dynamic>>.from(rows);
    } on TimeoutException {
      throw const ServerException('Join requests timed out.');
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<List<Map<String, dynamic>>> getTeamPendingClaimRequests(
    String teamId,
  ) async {
    try {
      final memberRows = await _supabase
          .from('team_members')
          .select('unclaimed_id')
          .eq('team_id', teamId)
          .eq('status', 'active')
          .not('unclaimed_id', 'is', null)
          .timeout(_readTimeout);
      final unclaimedIds = memberRows
          .map((row) => row['unclaimed_id'] as String?)
          .whereType<String>()
          .toList(growable: false);
      if (unclaimedIds.isEmpty) return const [];

      final rows = await _supabase
          .from('claim_requests')
          .select('''
            *,
            requester:profiles!requester_id(
              display_name,
              username,
              profile_photo_url
            ),
            unclaimed:unclaimed_players!unclaimed_id(display_name)
          ''')
          .inFilter('unclaimed_id', unclaimedIds)
          .eq('status', 'pending')
          .order('created_at', ascending: false)
          .timeout(_readTimeout);
      return List<Map<String, dynamic>>.from(rows);
    } on TimeoutException {
      throw const ServerException('Claim requests timed out.');
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      final clean = query.trim().replaceAll('@', '');
      if (clean.isEmpty) return const [];
      final rows = await _supabase
          .from('profiles')
          .select(
            'user_id, username, display_name, profile_photo_url, '
            'cricket_player_profiles(player_role)',
          )
          .or('username.ilike.%$clean%,display_name.ilike.%$clean%')
          .limit(20)
          .timeout(_readTimeout);
      return List<Map<String, dynamic>>.from(rows);
    } on TimeoutException {
      throw const ServerException('Player search timed out.');
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<void> addUnclaimedCricketPlayer({
    required String teamId,
    required String displayName,
    String? phoneNumber,
    int? jerseyNumber,
    String? playerRole,
    String? battingStyle,
    String? bowlingStyle,
    List<String> preferredBallTypes = const [],
    int? yearsPlaying,
  }) => _rpc('add_unclaimed_cricket_team_member', {
    'p_team_id': teamId,
    'p_display_name': displayName,
    'p_phone_number': phoneNumber,
    'p_jersey_number': jerseyNumber,
    'p_player_role': playerRole,
    'p_batting_style': battingStyle,
    'p_bowling_style': bowlingStyle,
    'p_preferred_ball_types': preferredBallTypes,
    'p_years_playing': yearsPlaying,
  });

  Future<void> sendTeamInvite({
    required String teamId,
    required String inviteeId,
    String? message,
    required String role,
    int? jerseyNumber,
  }) async {
    final uid = _requireUid();
    try {
      await _supabase.from('team_invites').insert({
        'team_id': teamId,
        'invitee_id': inviteeId,
        'invited_by': uid,
        'role': role,
        'status': 'pending',
        if (message != null && message.trim().isNotEmpty)
          'message': message.trim(),
        if (jerseyNumber != null) 'jersey_number': jerseyNumber,
      });
    } on PostgrestException catch (e) {
      if (e.code == '42501') throw UnauthorizedException(e.message);
      throw ServerException(e.message);
    }
  }

  Future<void> setJerseyNumber(String membershipId, int? jersey) => _rpc(
    'set_team_member_jersey',
    {'p_membership_id': membershipId, 'p_jersey_number': jersey},
  );

  Future<void> assignCaptain(String membershipId) =>
      _rpc('assign_team_captain', {'p_membership_id': membershipId});

  Future<void> revokeCaptain(String membershipId) => _rpc('revoke_team_role', {
    'p_membership_id': membershipId,
    'p_role_key': 'captain',
  });

  Future<void> promoteToManager(String membershipId) => _rpc(
    'set_team_member_base_role',
    {'p_membership_id': membershipId, 'p_role_key': 'manager'},
  );

  Future<void> demoteToPlayer(String membershipId) => _rpc(
    'set_team_member_base_role',
    {'p_membership_id': membershipId, 'p_role_key': 'player'},
  );

  Future<void> removeMember(String membershipId) =>
      _rpc('remove_team_member', {'p_membership_id': membershipId});

  Future<void> leaveTeam(String membershipId) =>
      _rpc('leave_team', {'p_membership_id': membershipId});

  Future<void> acceptTeamInvite(String inviteId) =>
      _rpc('accept_team_invite', {'p_invite_id': inviteId});
  Future<void> declineTeamInvite(String inviteId) =>
      _rpc('decline_team_invite', {'p_invite_id': inviteId});
  Future<void> cancelTeamInvite(String inviteId) =>
      _rpc('cancel_team_invite', {'p_invite_id': inviteId});

  Future<void> acceptJoinRequest(String requestId) =>
      _rpc('accept_team_join_request', {'p_request_id': requestId});
  Future<void> declineJoinRequest(String requestId) =>
      _rpc('decline_team_join_request', {'p_request_id': requestId});
  Future<void> approveClaimRequest(String requestId) =>
      _rpc('approve_claim_request', {'p_request_id': requestId});
  Future<void> rejectClaimRequest(String requestId) =>
      _rpc('reject_claim_request', {'p_request_id': requestId});

  Future<void> requestToJoinTeam({required String teamId, String? message}) =>
      _rpc('request_to_join_team', {
        'p_team_id': teamId,
        'p_role': 'player',
        if (message != null && message.trim().isNotEmpty)
          'p_message': message.trim(),
      });

  Future<void> _rpc(String name, Map<String, dynamic> params) async {
    try {
      _requireUid();
      await _supabase.rpc<dynamic>(name, params: params);
    } on PostgrestException catch (e) {
      if (e.code == '28000') {
        throw UnauthorizedException(e.message);
      }
      if (e.code == '42501') {
        // Distinguish intentional RPC-level authorization rejections
        // (RAISE EXCEPTION … USING ERRCODE = '42501') from raw Postgres ACL
        // failures ("permission denied for table …"). The former is a domain
        // decision; the latter is an infrastructure misconfiguration that
        // callers should not silently swallow as a user-facing auth error.
        final msg = e.message.toLowerCase();
        final isRawPrivilege = msg.startsWith('permission denied');
        if (!isRawPrivilege) throw UnauthorizedException(e.message);
        throw ServerException(e.message);
      }
      if (e.code == 'P0002') throw NotFoundException(e.message);
      if (e.code == '23505') {
        throw ServerException(
          e.message.toLowerCase().contains('jersey')
              ? 'That jersey number is already taken'
              : e.message,
        );
      }
      throw ServerException(e.message);
    }
  }
}
