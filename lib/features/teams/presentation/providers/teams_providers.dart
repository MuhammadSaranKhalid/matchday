import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/supabase/supabase_client_provider.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/teams_datasource_providers.dart';
import '../../data/repositories/teams_repository_impl.dart';
import '../../domain/entities/roster_member.dart';
import '../../domain/entities/team.dart';
import '../../domain/repositories/teams_repository.dart';
import '../../domain/usecases/add_unclaimed_player.dart';
import '../../domain/usecases/create_team.dart';
import '../../domain/usecases/get_team.dart';
import '../../domain/usecases/remove_member.dart';
import '../../domain/usecases/set_jersey_number.dart';
import '../../domain/usecases/set_member_role.dart';
import '../../domain/usecases/upload_team_logo.dart';
import '../../domain/usecases/watch_all_teams.dart';
import '../../domain/usecases/watch_my_teams.dart';
import '../../domain/usecases/watch_roster.dart';
import '../../domain/usecases/watch_team.dart';

part 'teams_providers.g.dart';

@Riverpod(keepAlive: true)
TeamsRepository teamsRepository(Ref ref) => TeamsRepositoryImpl(
      remote: ref.watch(teamsRemoteDataSourceProvider),
      supabase: ref.watch(supabaseClientProvider),
    );

@riverpod
CreateTeam createTeamUseCase(Ref ref) =>
    CreateTeam(ref.watch(teamsRepositoryProvider));

@riverpod
UploadTeamLogo uploadTeamLogoUseCase(Ref ref) =>
    UploadTeamLogo(ref.watch(teamsRepositoryProvider));

@riverpod
WatchMyTeams watchMyTeamsUseCase(Ref ref) =>
    WatchMyTeams(ref.watch(teamsRepositoryProvider));

@riverpod
WatchAllTeams watchAllTeamsUseCase(Ref ref) =>
    WatchAllTeams(ref.watch(teamsRepositoryProvider));

@riverpod
WatchTeam watchTeamUseCase(Ref ref) =>
    WatchTeam(ref.watch(teamsRepositoryProvider));

@riverpod
GetTeam getTeamUseCase(Ref ref) => GetTeam(ref.watch(teamsRepositoryProvider));

@riverpod
WatchRoster watchRosterUseCase(Ref ref) =>
    WatchRoster(ref.watch(teamsRepositoryProvider));

@riverpod
AddUnclaimedPlayer addUnclaimedPlayerUseCase(Ref ref) =>
    AddUnclaimedPlayer(ref.watch(teamsRepositoryProvider));

@riverpod
RemoveMember removeMemberUseCase(Ref ref) =>
    RemoveMember(ref.watch(teamsRepositoryProvider));

@riverpod
SetJerseyNumber setJerseyNumberUseCase(Ref ref) =>
    SetJerseyNumber(ref.watch(teamsRepositoryProvider));

@riverpod
SetMemberRole setMemberRoleUseCase(Ref ref) =>
    SetMemberRole(ref.watch(teamsRepositoryProvider));

// ─── Reactive reads (Supabase realtime streams) ────────────────────────────

/// Teams owned/managed by the signed-in user. Empty when signed out.
@riverpod
Stream<List<Team>> myTeams(Ref ref) {
  final userId = ref.watch(currentUserStreamProvider).value?.id.value;
  if (userId == null) return Stream.value(const []);
  return ref.watch(watchMyTeamsUseCaseProvider).call(userId);
}

/// All teams visible to the signed-in user (used by match setup's opponent
/// picker).
@riverpod
Stream<List<Team>> allTeams(Ref ref) =>
    ref.watch(watchAllTeamsUseCaseProvider).call(const NoParams());

/// A single team (hub view). Null if not found / not accessible.
@riverpod
Stream<Team?> team(Ref ref, String teamId) =>
    ref.watch(watchTeamUseCaseProvider).call(TeamId(teamId));

/// A team's roster (members + display names).
@riverpod
Stream<List<RosterMember>> roster(Ref ref, String teamId) =>
    ref.watch(watchRosterUseCaseProvider).call(TeamId(teamId));
