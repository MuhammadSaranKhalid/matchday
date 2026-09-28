import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/supabase/supabase_auth_state_provider.dart';
import '../../data/datasources/team_membership_datasource_providers.dart';
import '../../data/repositories/team_membership_repository_impl.dart';
import '../../domain/entities/roster_member.dart';
import '../../domain/entities/team.dart';
import '../../domain/entities/team_claim_request.dart';
import '../../domain/entities/team_invite.dart';
import '../../domain/entities/team_join_request.dart';
import '../../domain/entities/team_membership.dart';
import '../../domain/repositories/team_membership_repository.dart';

part 'team_membership_providers.g.dart';

@Riverpod(keepAlive: true)
TeamMembershipRepository teamMembershipRepository(Ref ref) =>
    TeamMembershipRepositoryImpl(
      remote: ref.watch(teamMembershipRemoteDataSourceProvider),
    );

@riverpod
Future<List<TeamMembership>> currentUserTeamMemberships(Ref ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const [];
  final result = await ref
      .watch(teamMembershipRepositoryProvider)
      .getCurrentUserMemberships();
  return result.fold(
    (failure) => throw FailureWrapper(failure),
    (value) => value,
  );
}

@riverpod
Future<List<TeamMembership>> userTeamMemberships(
  Ref ref,
  String userId,
) async {
  final result = await ref
      .watch(teamMembershipRepositoryProvider)
      .getUserMemberships(userId);
  return result.fold(
    (failure) => throw FailureWrapper(failure),
    (value) => value,
  );
}

@riverpod
Future<TeamMembership?> currentTeamMembership(Ref ref, String teamId) async {
  final result = await ref
      .watch(teamMembershipRepositoryProvider)
      .getCurrentUserMembershipForTeam(TeamId(teamId));
  return result.fold((failure) => throw FailureWrapper(failure), (value) => value);
}

@riverpod
Future<List<RosterMember>> roster(Ref ref, String teamId) async {
  final result = await ref
      .watch(teamMembershipRepositoryProvider)
      .getRoster(TeamId(teamId));
  return result.fold((failure) => throw FailureWrapper(failure), (value) => value);
}

@riverpod
Future<TeamInvite?> myPendingInviteForTeam(Ref ref, String teamId) async {
  final result = await ref
      .watch(teamMembershipRepositoryProvider)
      .getMyPendingInviteForTeam(TeamId(teamId));
  return result.fold((failure) => throw FailureWrapper(failure), (value) => value);
}

@riverpod
Future<List<TeamInvite>> teamPendingInvites(Ref ref, String teamId) async {
  final result = await ref
      .watch(teamMembershipRepositoryProvider)
      .getTeamPendingInvites(TeamId(teamId));
  return result.fold((failure) => throw FailureWrapper(failure), (value) => value);
}

@riverpod
Future<List<TeamClaimRequest>> teamPendingClaimRequests(
  Ref ref,
  String teamId,
) async {
  final result = await ref
      .watch(teamMembershipRepositoryProvider)
      .getTeamPendingClaimRequests(TeamId(teamId));
  return result.fold((failure) => throw FailureWrapper(failure), (value) => value);
}

@riverpod
Future<List<TeamJoinRequest>> teamPendingJoinRequests(
  Ref ref,
  String teamId,
) async {
  final result = await ref
      .watch(teamMembershipRepositoryProvider)
      .getTeamPendingJoinRequests(TeamId(teamId));
  return result.fold((failure) => throw FailureWrapper(failure), (value) => value);
}
