import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/teams_datasource_providers.dart';
import '../../data/repositories/teams_repository_impl.dart';
import '../../domain/entities/roster_member.dart';
import '../../domain/entities/team.dart';
import '../../domain/repositories/teams_repository.dart';

part 'teams_providers.g.dart';

@Riverpod(keepAlive: true)
TeamsRepository teamsRepository(Ref ref) => TeamsRepositoryImpl(
      remote: ref.watch(teamsRemoteDataSourceProvider),
    );

// ─── Reactive reads (Supabase realtime streams) ────────────────────────────

/// Teams owned/managed by the signed-in user. Empty when signed out.
@riverpod
Stream<List<Team>> myTeams(Ref ref) {
  final userId = ref.watch(currentUserStreamProvider).value?.id.value;
  if (userId == null) return Stream.value(const []);
  return ref.watch(teamsRepositoryProvider).watchMyTeams(userId);
}

/// All teams visible to the signed-in user (used by match setup's opponent
/// picker).
@riverpod
Stream<List<Team>> allTeams(Ref ref) =>
    ref.watch(teamsRepositoryProvider).watchAllTeams();

/// A single team (hub view). Null if not found / not accessible.
@riverpod
Stream<Team?> team(Ref ref, String teamId) =>
    ref.watch(teamsRepositoryProvider).watchTeam(TeamId(teamId));

/// A team's roster (members + display names).
@riverpod
Stream<List<RosterMember>> roster(Ref ref, String teamId) =>
    ref.watch(teamsRepositoryProvider).watchRoster(TeamId(teamId));

/// Team invites sent to players for a team.
@riverpod
Future<List<Map<String, dynamic>>> teamPendingInvites(Ref ref, String teamId) =>
    ref.watch(teamsRemoteDataSourceProvider).getTeamInvites(teamId);

/// Claim requests from users claiming unclaimed roster spots for a team.
@riverpod
Future<List<Map<String, dynamic>>> teamPendingClaimRequests(Ref ref, String teamId) =>
    ref.watch(teamsRemoteDataSourceProvider).getClaimRequests(teamId);

/// Join requests from players asking to join a team.
@riverpod
Future<List<Map<String, dynamic>>> teamPendingJoinRequests(Ref ref, String teamId) =>
    ref.watch(teamsRemoteDataSourceProvider).getTeamJoinRequests(teamId);

class UserTeamAffiliation {
  const UserTeamAffiliation({
    required this.teamId,
    required this.teamName,
    required this.logoMonogram,
    this.logoUrl,
    this.primaryColor,
    required this.role,
    required this.isCaptain,
  });

  final String teamId;
  final String teamName;
  final String logoMonogram;
  final String? logoUrl;
  final String? primaryColor;
  final String role;
  final bool isCaptain;
}

/// Real-time stream of all teams affiliated with a user (captained and played for).
@riverpod
Stream<List<UserTeamAffiliation>> userAffiliatedTeams(Ref ref, String userId) {
  final remote = ref.watch(teamsRemoteDataSourceProvider);
  return ref.watch(teamsRepositoryProvider).watchAllTeams().asyncMap((allTeams) async {
    try {
      final members = await remote.listMembers();
      final myMemberships = members.where((m) => m.userId == userId).toList();
      final memberByTeamId = {for (final m in myMemberships) m.teamId: m};

      final List<UserTeamAffiliation> result = [];
      for (final t in allTeams) {
        final member = memberByTeamId[t.id.value];
        final isOwner = t.ownerId == userId;
        final isManager = t.managers.contains(userId);
        final isCaptainRole = member?.role == 'captain';

        if (isOwner || isManager || isCaptainRole || member != null) {
          final isCaptain = isOwner || isManager || isCaptainRole;
          final roleStr = isOwner || isCaptainRole
              ? 'CAPTAIN'
              : isManager
                  ? 'MANAGER'
                  : switch (member?.role) {
                      'vice_captain' => 'VICE CAPTAIN',
                      'wicket_keeper' => 'WICKET-KEEPER',
                      _ => 'PLAYER',
                    };

          result.add(
            UserTeamAffiliation(
              teamId: t.id.value,
              teamName: t.name,
              logoMonogram: t.logoMonogram ?? (t.name.isNotEmpty ? t.name[0].toUpperCase() : 'T'),
              logoUrl: t.logoUrl,
              primaryColor: t.primaryColor,
              role: roleStr,
              isCaptain: isCaptain,
            ),
          );
        }
      }
      return result;
    } catch (_) {
      return <UserTeamAffiliation>[];
    }
  });
}

