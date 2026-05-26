import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/exceptions.dart';
import '../models/team_dto.dart';
import '../models/team_member_dto.dart';
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
      // RLS scopes to rows the signed-in user added.
      final rows = await _supabase.from(_unclaimed).select();
      return rows.map(UnclaimedPlayerDto.fromJson).toList();
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
            'location': {if (payload['city'] != null) 'city': payload['city']},
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

  /// Uploads [file] to `team-logos/<teamId>/logo.<ext>` and patches the
  /// team row's `logo_url`. Returns the public URL. Mirrors the avatar
  /// upload pattern in `onboarding_remote_datasource.dart`.
  Future<String> uploadTeamLogo({
    required String teamId,
    required File file,
    required String contentType,
    required String extension,
  }) async {
    try {
      final path = '$teamId/logo.$extension';
      await _supabase.storage.from('team-logos').upload(
            path,
            file,
            fileOptions: FileOptions(
              contentType: contentType,
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

  Future<UnclaimedPlayerDto> createUnclaimed(
      Map<String, dynamic> payload) async {
    try {
      final row = await _supabase
          .from(_unclaimed)
          .insert({
            'unclaimed_id': payload['id'],
            'display_name': payload['display_name'],
            'added_by': _requireUid(),
          })
          .select()
          .single();
      return UnclaimedPlayerDto.fromJson(row);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<TeamMemberDto> createMember(Map<String, dynamic> payload) async {
    try {
      final row = await _supabase
          .from(_members)
          .insert({
            'membership_id': payload['id'],
            'team_id': payload['team_id'],
            'player_id': payload['player_id'],
            'player_type': payload['player_type'],
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
