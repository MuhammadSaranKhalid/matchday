import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/supabase/supabase_auth_state_provider.dart';
import '../../../teams/presentation/providers/team_membership_providers.dart';
import '../../../teams/presentation/providers/teams_providers.dart';
import '../../domain/entities/match.dart';
import '../../domain/entities/match_role.dart';
import '../widgets/match_detail/pv_v2_data.dart';
import '../widgets/match_detail/pv_v2_map.dart';
import 'matches_providers.dart';
import 'my_matches_providers.dart';

part 'match_detail_provider.g.dart';

@riverpod
Future<PvMatch?> matchDetail(
  Ref ref,
  String matchId,
) async {
  // Listen for realtime match updates. If the underlying match row changes
  // (e.g. status goes from scheduled to toss), invalidate the workspace provider
  // so the screen fetches the fresh state.
  ref.listen(liveMatchProvider(matchId), (prev, next) {
    if (next.hasValue && next.value != null && prev?.value != next.value) {
      ref.invalidate(myMatchesViewProvider);
    }
  });

  final view = await ref.watch(myMatchesViewProvider.future);
  final memberships =
      await ref.watch(currentUserTeamMembershipsProvider.future);

  final pvTeams = pvTeamsFromMemberships(memberships);
  final meFallback = pvTeams.isNotEmpty ? pvTeams.first.crest : kPvUnknownCrest;

  for (final m in pvMatchesFromView(view, meFallback: meFallback)) {
    if (m.id == matchId) {
      return m;
    }
  }

  // Direct lookup fallback
  final directMatch = await ref.watch(matchProvider(matchId).future);
  if (directMatch != null) {
    final teamAResult =
        await ref.read(teamsRepositoryProvider).getTeam(directMatch.teamAId);
    final teamBResult =
        await ref.read(teamsRepositoryProvider).getTeam(directMatch.teamBId);
    final teamA = teamAResult.fold((_) => null, (t) => t);
    final teamB = teamBResult.fold((_) => null, (t) => t);

    final myRoles = {
      for (final mem in memberships) mem.team.id.value: mem.relationship
    };
    final userTeamIds = {
      if (myRoles[directMatch.teamAId.value]?.hasMatchAuthority ?? false)
        directMatch.teamAId.value,
      if (myRoles[directMatch.teamBId.value]?.hasMatchAuthority ?? false)
        directMatch.teamBId.value,
    };
    final currentUserId = ref.watch(currentUserIdProvider) ?? '';
    final role = roleOnMatch(directMatch, currentUserId,
        userTeamIds: userTeamIds);
    final isCaptain = role == MatchRoleKind.captain;

    final when = directMatch.scheduledStartTime != null
        ? '${directMatch.scheduledStartTime!.day}/${directMatch.scheduledStartTime!.month} · ${directMatch.scheduledStartTime!.hour.toString().padLeft(2, '0')}:${directMatch.scheduledStartTime!.minute.toString().padLeft(2, '0')}'
        : 'TBD';

    return PvMatch(
      id: directMatch.id.value,
      phase: directMatch.status.isLive
          ? PvPhase.live
          : directMatch.status == MatchStatus.completed
              ? PvPhase.completed
              : PvPhase.scheduled,
      me: teamA != null ? crestFromTeam(teamA) : kPvUnknownCrest,
      them: teamB != null ? crestFromTeam(teamB) : kPvUnknownCrest,
      role: isCaptain ? 'captain' : 'player',
      when: when,
      venue: directMatch.venue?.ground ?? 'TBD',
      sub: directMatch.matchType.label,
      oversPerInnings: directMatch.format.oversPerInnings,
      ballsPerOver: directMatch.format.ballsPerOver,
      playersPerTeam: directMatch.format.playersPerTeam,
      ballType: directMatch.format.ballType.wire,
      formatCode: directMatch.matchType == MatchType.tournament
          ? 'Tournament'
          : (directMatch.format.oversPerInnings == 20
              ? 'T20'
              : (directMatch.format.oversPerInnings > 0
                  ? '${directMatch.format.oversPerInnings}O'
                  : 'Cricket')),
    );
  }

  return null;
}
