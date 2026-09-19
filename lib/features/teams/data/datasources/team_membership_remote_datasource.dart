import 'package:flutter/rendering.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../models/team_dto.dart';
import '../models/team_member_dto.dart';

typedef TeamMembershipRecord = ({
  TeamMemberDto member,
  TeamDto team,
});

/// Supabase read source for team membership.
///
/// One request starts at the authenticated user's active `team_members` rows
/// and embeds:
///   - the related `teams` row
///   - the membership's `team_member_roles` rows
///
/// No `.stream()`, Realtime publication, or WebSocket is used here.
class TeamMembershipRemoteDataSource {
  TeamMembershipRemoteDataSource(this._supabase);

  final SupabaseClient _supabase;

  String _requireUid() {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) {
      throw UnauthorizedException('Must be signed in');
    }
    return uid;
  }

  Future<List<TeamMembershipRecord>> getCurrentUserMemberships() async {
    try {
      final uid = _requireUid();

      final rows = await _supabase
          .from('team_members')
          .select('''
            membership_id,
            team_id,
            user_id,
            unclaimed_id,
            jersey_number,
            added_by,
            joined_at,
            updated_at,
            team_member_roles (
              role_key
            ),
            team:teams!team_members_team_id_fkey (
              team_id,
              created_by,
              team_name,
              team_type,
              description,
              home_ground,
              location,
              founded_year,
              team_colors,
              privacy,
              tagline,
              logo_url,
              logo_monogram,
              is_verified,
              status,
              created_at,
              updated_at
            )
          ''')
          .eq('user_id', uid)
          .eq('status', 'active')
          .order('joined_at');
      
      debugPrint(rows.toString());

      final result = <TeamMembershipRecord>[];

      for (final row in rows) {
        final teamJson = row['team'];
        if (teamJson is! Map) {
          throw ServerException(
            'Active team membership is missing its team record',
          );
        }

        result.add((
          member: TeamMemberDto.fromJson(
            Map<String, dynamic>.from(row),
          ),
          team: TeamDto.fromJson(
            Map<String, dynamic>.from(teamJson),
          ),
        ));
      }

      return result;
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }
}
