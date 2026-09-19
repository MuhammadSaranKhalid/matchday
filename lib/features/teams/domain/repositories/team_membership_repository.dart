import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/player_skills.dart';
import '../entities/roster_member.dart';
import '../entities/team.dart';
import '../entities/team_claim_request.dart';
import '../entities/team_invite.dart';
import '../entities/team_join_request.dart';
import '../entities/team_membership.dart';
import '../entities/team_member.dart';
import '../value_objects/jersey_number.dart';
import '../value_objects/player_display_name.dart';

/// One-shot membership/roster boundary plus explicit membership commands.
///
/// There are deliberately no generic role setters, raw member inserts/deletes,
/// or permanent realtime streams here. Every authority-changing mutation maps
/// to one server-side workflow with one business meaning.
abstract class TeamMembershipRepository {
  Future<Either<Failure, List<TeamMembership>>> getCurrentUserMemberships();

  /// One-shot public membership view for a profile user. RLS decides which
  /// memberships are visible to the current viewer (public teams for other
  /// users; own private memberships remain visible to the member).
  Future<Either<Failure, List<TeamMembership>>> getUserMemberships(
    String userId,
  );

  Future<Either<Failure, TeamMembership?>> getCurrentUserMembershipForTeam(
    TeamId teamId,
  );

  Future<Either<Failure, List<RosterMember>>> getRoster(TeamId teamId);

  Future<Either<Failure, TeamInvite?>> getMyPendingInviteForTeam(TeamId teamId);
  Future<Either<Failure, List<TeamInvite>>> getTeamPendingInvites(TeamId teamId);
  Future<Either<Failure, List<TeamClaimRequest>>> getTeamPendingClaimRequests(
    TeamId teamId,
  );
  Future<Either<Failure, List<TeamJoinRequest>>> getTeamPendingJoinRequests(
    TeamId teamId,
  );

  Future<Either<Failure, List<Map<String, dynamic>>>> searchUsers(String query);

  Future<Either<Failure, Unit>> addUnclaimedPlayer({
    required TeamId teamId,
    required PlayerDisplayName displayName,
    String? phoneNumber,
    JerseyNumber? jerseyNumber,
    PlayingRole? playingRole,
    BattingStyle? battingStyle,
    BowlingStyle? bowlingStyle,
  });

  Future<Either<Failure, Unit>> sendTeamInvite({
    required TeamId teamId,
    required String inviteeId,
    String? message,
    MemberRole role = MemberRole.player,
    int? jerseyNumber,
  });

  Future<Either<Failure, Unit>> setJerseyNumber(
    MembershipId membershipId,
    JerseyNumber? jersey,
  );
  Future<Either<Failure, Unit>> assignCaptain(MembershipId membershipId);
  Future<Either<Failure, Unit>> revokeCaptain(MembershipId membershipId);
  Future<Either<Failure, Unit>> promoteToManager(MembershipId membershipId);
  Future<Either<Failure, Unit>> demoteToPlayer(MembershipId membershipId);
  Future<Either<Failure, Unit>> removeMember(MembershipId membershipId);
  Future<Either<Failure, Unit>> leaveTeam(MembershipId membershipId);

  Future<Either<Failure, Unit>> acceptTeamInvite(String inviteId);
  Future<Either<Failure, Unit>> declineTeamInvite(String inviteId);
  Future<Either<Failure, Unit>> cancelTeamInvite(String inviteId);

  Future<Either<Failure, Unit>> acceptJoinRequest(String requestId);
  Future<Either<Failure, Unit>> declineJoinRequest(String requestId);
  Future<Either<Failure, Unit>> approveClaimRequest(String requestId);
  Future<Either<Failure, Unit>> rejectClaimRequest(String requestId);

  Future<Either<Failure, Unit>> requestToJoinTeam({
    required TeamId teamId,
    String? message,
  });
}
