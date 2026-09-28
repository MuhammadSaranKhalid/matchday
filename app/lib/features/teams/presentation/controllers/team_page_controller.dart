import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../../matches/domain/entities/match.dart';
import '../../../matches/presentation/providers/matches_providers.dart';
import '../../domain/entities/team.dart';
import '../../domain/entities/team_invite.dart';
import '../../domain/entities/team_member.dart';
import '../providers/team_membership_providers.dart';
import '../providers/teams_providers.dart';
import '../state/team_page_state.dart';
import 'teams_list_controller.dart';

part 'team_page_controller.g.dart';

@riverpod
class TeamPageController extends _$TeamPageController {
  @override
  Future<TeamPageState?> build(String teamId) => _load();

  Future<TeamPageState?> _load() async {
    final id = TeamId(teamId);

    final teamResult = await ref.read(teamsRepositoryProvider).getTeam(id);
    final team = teamResult.fold(
      (failure) => throw FailureWrapper(failure),
      (value) => value,
    );
    if (team == null) return null;

    final membershipFuture = ref
        .read(teamMembershipRepositoryProvider)
        .getCurrentUserMembershipForTeam(id);
    final rosterFuture =
        ref.read(teamMembershipRepositoryProvider).getRoster(id);
    final inviteFuture = ref
        .read(teamMembershipRepositoryProvider)
        .getMyPendingInviteForTeam(id);

    // Public-board query, then scope to the viewed team. This deliberately
    // does NOT use the viewer-scoped My Matches query.
    final now = DateTime.now();
    final matchesFuture = ref.read(matchesRepositoryProvider).listPublicMatches(
          statuses: const {
            MatchStatus.scheduled,
            MatchStatus.toss,
            MatchStatus.rescheduled,
            MatchStatus.live,
            MatchStatus.inningsBreak,
            MatchStatus.superOver,
            MatchStatus.completed,
            MatchStatus.abandoned,
            MatchStatus.tied,
            MatchStatus.noResult,
            MatchStatus.walkover,
          },
          from: now.subtract(const Duration(days: 3650)),
          to: now.add(const Duration(days: 3650)),
          newestFirst: true,
        );

    final membershipResult = await membershipFuture;
    final rosterResult = await rosterFuture;
    final inviteResult = await inviteFuture;
    final matchesResult = await matchesFuture;

    final membership = membershipResult.fold(
      (failure) => throw FailureWrapper(failure),
      (value) => value,
    );
    final roster = rosterResult.fold(
      (failure) => throw FailureWrapper(failure),
      (value) => value,
    );
    final pendingInvite = inviteResult.fold<TeamInvite?>(
      (_) => null,
      (value) => value,
    );
    final publicMatches = matchesResult.fold<List<Match>>(
      (failure) => throw FailureWrapper(failure),
      (value) => value,
    );

    final scopedMatches = publicMatches
        .where(
          (match) => match.teamAId == id || match.teamBId == id,
        )
        .toList(growable: false);

    final opponentIds = <String>{
      for (final match in scopedMatches)
        if (match.teamAId == id) match.teamBId.value else match.teamAId.value,
    };
    final opponentsResult = await ref
        .read(teamsRepositoryProvider)
        .getTeamsByIds(opponentIds.map(TeamId.new));
    final opponentNames = opponentsResult.fold<Map<String, String>>(
      (_) => const <String, String>{},
      (teams) => {
        for (final entry in teams.entries) entry.key: entry.value.name,
      },
    );

    return TeamPageState(
      team: team,
      membership: membership,
      roster: roster,
      matches: scopedMatches,
      pendingInvite: pendingInvite,
      opponentNames: Map<String, String>.unmodifiable(opponentNames),
    );
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(_load);
  }

  Future<String?> requestToJoin({String? message}) => _runMembership(
        () => ref.read(teamMembershipRepositoryProvider).requestToJoinTeam(
              teamId: TeamId(teamId),
              message: message,
            ),
      );

  Future<String?> acceptInvite(String inviteId) => _runMembership(
        () => ref
            .read(teamMembershipRepositoryProvider)
            .acceptTeamInvite(inviteId),
        refreshMyTeams: true,
      );

  Future<String?> declineInvite(String inviteId) => _runMembership(
        () => ref
            .read(teamMembershipRepositoryProvider)
            .declineTeamInvite(inviteId),
      );

  Future<String?> leaveTeam(MembershipId membershipId) => _runMembership(
        () => ref
            .read(teamMembershipRepositoryProvider)
            .leaveTeam(membershipId),
        refreshMyTeams: true,
      );

  Future<String?> setStatus(TeamStatus status) async {
    final result = await ref.read(teamsRepositoryProvider).setTeamStatus(
          teamId: TeamId(teamId),
          status: status,
        );

    final error = result.fold<String?>(
      (failure) => failure.message,
      (_) => null,
    );
    if (error == null) {
      ref.invalidate(teamProvider(teamId));
      ref.invalidate(teamsListControllerProvider);
      await refresh();
    }
    return error;
  }

  Future<String?> _runMembership(
    Future<Either<Failure, Unit>> Function() operation, {
    bool refreshMyTeams = false,
  }) async {
    final result = await operation();
    final error = result.fold<String?>(
      (failure) => failure.message,
      (_) => null,
    );
    if (error == null) {
      ref.invalidate(currentTeamMembershipProvider(teamId));
      ref.invalidate(rosterProvider(teamId));
      if (refreshMyTeams) {
        ref.invalidate(teamsListControllerProvider);
      }
      await refresh();
    }
    return error;
  }
}
