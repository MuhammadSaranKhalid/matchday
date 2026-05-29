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
