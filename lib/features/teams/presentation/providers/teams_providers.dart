import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/teams_datasource_providers.dart';
import '../../data/repositories/teams_repository_impl.dart';
import '../../domain/entities/roster_member.dart';
import '../../domain/entities/team.dart';
import '../../domain/entities/team_claim_request.dart';
import '../../domain/entities/team_invite.dart';
import '../../domain/entities/team_join_request.dart';
import '../../domain/entities/team_member.dart';
import '../../domain/entities/user_team_affiliation.dart';
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

/// All teams visible to the signed-in user (used by match setup's opponent picker).
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

/// The signed-in user's rung on each of their teams, keyed by team id.
/// Ask this rather than comparing against `Team.ownerId` — see
/// docs/team-roles-design.md.
@riverpod
Stream<Map<String, MemberRole>> myTeamRoles(Ref ref) {
  final userId = ref.watch(currentUserStreamProvider).value?.id.value;
  if (userId == null) return Stream.value(const {});
  return ref.watch(teamsRepositoryProvider).watchMyTeamRoles(userId);
}

/// Real-time stream of all teams affiliated with a user (captained and played for).
@riverpod
Stream<List<UserTeamAffiliation>> userAffiliatedTeams(Ref ref, String userId) =>
    ref.watch(teamsRepositoryProvider).watchUserAffiliatedTeams(userId);

/// Team invites sent to players for a team.
@riverpod
Future<List<TeamInvite>> teamPendingInvites(Ref ref, String teamId) async {
  final res =
      await ref.watch(teamsRepositoryProvider).getTeamPendingInvites(teamId);
  return res.getOrElse((_) => const []);
}

/// Claim requests from users claiming unclaimed roster spots for a team.
@riverpod
Future<List<TeamClaimRequest>> teamPendingClaimRequests(
    Ref ref, String teamId) async {
  final res = await ref
      .watch(teamsRepositoryProvider)
      .getTeamPendingClaimRequests(teamId);
  return res.getOrElse((_) => const []);
}

/// Join requests from players asking to join a team.
@riverpod
Future<List<TeamJoinRequest>> teamPendingJoinRequests(
    Ref ref, String teamId) async {
  final res =
      await ref.watch(teamsRepositoryProvider).getTeamPendingJoinRequests(teamId);
  return res.getOrElse((_) => const []);
}


