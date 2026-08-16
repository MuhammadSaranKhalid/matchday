import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/team_member.dart';
import '../../domain/value_objects/jersey_number.dart';
import '../providers/teams_providers.dart';

part 'team_manage_controller.g.dart';

@riverpod
class TeamManageController extends _$TeamManageController {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  /// Sets or clears a squad member's jersey number.
  Future<String?> setJerseyNumber({
    required MembershipId memberId,
    required String teamId,
    required int? jersey,
  }) async {
    JerseyNumber? jerseyVo;
    if (jersey != null) {
      final res = JerseyNumber.create(jersey);
      if (res.isLeft()) {
        return res.getLeft().toNullable()!.message;
      }
      jerseyVo = res.getRight().toNullable();
    }

    state = const AsyncValue.loading();
    final repo = ref.read(teamsRepositoryProvider);
    final result = await repo.setJerseyNumber(memberId, jerseyVo);

    return result.fold(
      (failure) {
        state = AsyncValue.error(failure, StackTrace.current);
        return failure.message;
      },
      (_) {
        state = const AsyncValue.data(null);
        ref.invalidate(rosterProvider(teamId));
        ref.invalidate(teamProvider(teamId));
        return null;
      },
    );
  }

  /// Updates a squad member's role (Captain, Vice-Captain, Wicket-Keeper, Player).
  Future<String?> setMemberRole({
    required MembershipId memberId,
    required String teamId,
    required MemberRole role,
  }) async {
    state = const AsyncValue.loading();
    final repo = ref.read(teamsRepositoryProvider);
    final result = await repo.setMemberRole(memberId, role);

    return result.fold(
      (failure) {
        state = AsyncValue.error(failure, StackTrace.current);
        return failure.message;
      },
      (_) {
        state = const AsyncValue.data(null);
        ref.invalidate(rosterProvider(teamId));
        ref.invalidate(teamProvider(teamId));
        return null;
      },
    );
  }

  /// Removes a player from the active team squad.
  Future<String?> removeMember({
    required MembershipId memberId,
    required String teamId,
  }) async {
    state = const AsyncValue.loading();
    final repo = ref.read(teamsRepositoryProvider);
    final result = await repo.removeMember(memberId);

    return result.fold(
      (failure) {
        state = AsyncValue.error(failure, StackTrace.current);
        return failure.message;
      },
      (_) {
        state = const AsyncValue.data(null);
        ref.invalidate(rosterProvider(teamId));
        ref.invalidate(teamProvider(teamId));
        return null;
      },
    );
  }

  /// Accepts a player's join request.
  Future<String?> acceptJoinRequest({
    required String requestId,
    required String teamId,
  }) async {
    state = const AsyncValue.loading();
    final repo = ref.read(teamsRepositoryProvider);
    final result = await repo.acceptJoinRequest(requestId);

    return result.fold(
      (failure) {
        state = AsyncValue.error(failure, StackTrace.current);
        return failure.message;
      },
      (_) {
        state = const AsyncValue.data(null);
        ref.invalidate(teamPendingJoinRequestsProvider(teamId));
        ref.invalidate(rosterProvider(teamId));
        ref.invalidate(teamProvider(teamId));
        return null;
      },
    );
  }

  /// Declines a player's join request.
  Future<String?> declineJoinRequest({
    required String requestId,
    required String teamId,
  }) async {
    state = const AsyncValue.loading();
    final repo = ref.read(teamsRepositoryProvider);
    final result = await repo.declineJoinRequest(requestId);

    return result.fold(
      (failure) {
        state = AsyncValue.error(failure, StackTrace.current);
        return failure.message;
      },
      (_) {
        state = const AsyncValue.data(null);
        ref.invalidate(teamPendingJoinRequestsProvider(teamId));
        return null;
      },
    );
  }

  /// Approves a roster spot claim request.
  Future<String?> acceptClaimRequest({
    required String requestId,
    required String teamId,
  }) async {
    state = const AsyncValue.loading();
    final repo = ref.read(teamsRepositoryProvider);
    final result = await repo.acceptClaimRequest(requestId);

    return result.fold(
      (failure) {
        state = AsyncValue.error(failure, StackTrace.current);
        return failure.message;
      },
      (_) {
        state = const AsyncValue.data(null);
        ref.invalidate(teamPendingClaimRequestsProvider(teamId));
        ref.invalidate(rosterProvider(teamId));
        ref.invalidate(teamProvider(teamId));
        return null;
      },
    );
  }

  /// Declines a roster spot claim request.
  Future<String?> declineClaimRequest({
    required String requestId,
    required String teamId,
  }) async {
    state = const AsyncValue.loading();
    final repo = ref.read(teamsRepositoryProvider);
    final result = await repo.declineClaimRequest(requestId);

    return result.fold(
      (failure) {
        state = AsyncValue.error(failure, StackTrace.current);
        return failure.message;
      },
      (_) {
        state = const AsyncValue.data(null);
        ref.invalidate(teamPendingClaimRequestsProvider(teamId));
        return null;
      },
    );
  }

  /// Cancels an in-flight team invite.
  Future<String?> cancelTeamInvite({
    required String inviteId,
    required String teamId,
  }) async {
    state = const AsyncValue.loading();
    final repo = ref.read(teamsRepositoryProvider);
    final result = await repo.cancelTeamInvite(inviteId);

    return result.fold(
      (failure) {
        state = AsyncValue.error(failure, StackTrace.current);
        return failure.message;
      },
      (_) {
        state = const AsyncValue.data(null);
        ref.invalidate(teamPendingInvitesProvider(teamId));
        return null;
      },
    );
  }
}
