import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';

import '../../domain/entities/team_member.dart';
import '../../domain/value_objects/jersey_number.dart';
import '../providers/team_membership_providers.dart';
import 'team_page_controller.dart';
import 'teams_list_controller.dart';

part 'team_manage_controller.g.dart';

@riverpod
class TeamManageController extends _$TeamManageController {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<String?> setJerseyNumber({
    required MembershipId memberId,
    required String teamId,
    required int? jersey,
  }) async {
    JerseyNumber? value;
    if (jersey != null) {
      final validated = JerseyNumber.create(jersey);
      if (validated.isLeft()) {
        return validated.getLeft().toNullable()!.message;
      }
      value = validated.getRight().toNullable();
    }
    return _run(
      teamId,
      () => ref
          .read(teamMembershipRepositoryProvider)
          .setJerseyNumber(memberId, value),
      refreshRoster: true,
    );
  }

  Future<String?> assignCaptain({
    required MembershipId memberId,
    required String teamId,
  }) =>
      _run(
        teamId,
        () => ref.read(teamMembershipRepositoryProvider).assignCaptain(memberId),
        refreshRoster: true,
      );

  Future<String?> revokeCaptain({
    required MembershipId memberId,
    required String teamId,
  }) =>
      _run(
        teamId,
        () => ref.read(teamMembershipRepositoryProvider).revokeCaptain(memberId),
        refreshRoster: true,
      );

  Future<String?> promoteToManager({
    required MembershipId memberId,
    required String teamId,
  }) =>
      _run(
        teamId,
        () => ref
            .read(teamMembershipRepositoryProvider)
            .promoteToManager(memberId),
        refreshRoster: true,
        refreshMembership: true,
      );

  Future<String?> demoteToPlayer({
    required MembershipId memberId,
    required String teamId,
  }) =>
      _run(
        teamId,
        () => ref
            .read(teamMembershipRepositoryProvider)
            .demoteToPlayer(memberId),
        refreshRoster: true,
        refreshMembership: true,
      );

  Future<String?> removeMember({
    required MembershipId memberId,
    required String teamId,
  }) =>
      _run(
        teamId,
        () => ref.read(teamMembershipRepositoryProvider).removeMember(memberId),
        refreshRoster: true,
        refreshMembership: true,
        refreshMyTeams: true,
      );

  Future<String?> acceptJoinRequest({
    required String requestId,
    required String teamId,
  }) =>
      _run(
        teamId,
        () => ref
            .read(teamMembershipRepositoryProvider)
            .acceptJoinRequest(requestId),
        refreshRoster: true,
        refreshJoinRequests: true,
      );

  Future<String?> declineJoinRequest({
    required String requestId,
    required String teamId,
  }) =>
      _run(
        teamId,
        () => ref
            .read(teamMembershipRepositoryProvider)
            .declineJoinRequest(requestId),
        refreshJoinRequests: true,
      );

  Future<String?> acceptClaimRequest({
    required String requestId,
    required String teamId,
  }) =>
      _run(
        teamId,
        () => ref
            .read(teamMembershipRepositoryProvider)
            .approveClaimRequest(requestId),
        refreshRoster: true,
        refreshClaimRequests: true,
      );

  Future<String?> declineClaimRequest({
    required String requestId,
    required String teamId,
  }) =>
      _run(
        teamId,
        () => ref
            .read(teamMembershipRepositoryProvider)
            .rejectClaimRequest(requestId),
        refreshClaimRequests: true,
      );

  Future<String?> cancelTeamInvite({
    required String inviteId,
    required String teamId,
  }) =>
      _run(
        teamId,
        () => ref
            .read(teamMembershipRepositoryProvider)
            .cancelTeamInvite(inviteId),
        refreshInvites: true,
      );

  Future<String?> _run(
    String teamId,
    Future<Either<Failure, Unit>> Function() operation, {
    bool refreshRoster = false,
    bool refreshMembership = false,
    bool refreshJoinRequests = false,
    bool refreshClaimRequests = false,
    bool refreshInvites = false,
    bool refreshMyTeams = false,
  }) async {
    state = const AsyncValue.loading();
    final result = await operation();

    return result.fold(
      (failure) {
        state = AsyncValue.error(failure, StackTrace.current);
        return failure.message;
      },
      (_) {
        state = const AsyncValue.data(null);
        if (refreshRoster) ref.invalidate(rosterProvider(teamId));
        if (refreshMembership) {
          ref.invalidate(currentTeamMembershipProvider(teamId));
        }
        if (refreshJoinRequests) {
          ref.invalidate(teamPendingJoinRequestsProvider(teamId));
        }
        if (refreshClaimRequests) {
          ref.invalidate(teamPendingClaimRequestsProvider(teamId));
        }
        if (refreshInvites) {
          ref.invalidate(teamPendingInvitesProvider(teamId));
        }
        ref.invalidate(teamPageControllerProvider(teamId));
        if (refreshMyTeams) ref.invalidate(teamsListControllerProvider);
        return null;
      },
    );
  }
}
