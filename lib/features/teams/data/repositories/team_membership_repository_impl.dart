import 'package:fpdart/fpdart.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/player_skills.dart';
import '../../domain/entities/roster_member.dart';
import '../../domain/entities/team.dart';
import '../../domain/entities/team_claim_request.dart';
import '../../domain/entities/team_invite.dart';
import '../../domain/entities/team_join_request.dart';
import '../../domain/entities/team_membership.dart';
import '../../domain/entities/team_member.dart';
import '../../domain/repositories/team_membership_repository.dart';
import '../../domain/value_objects/jersey_number.dart';
import '../../domain/value_objects/player_display_name.dart';
import '../datasources/team_membership_remote_datasource.dart';

class TeamMembershipRepositoryImpl implements TeamMembershipRepository {
  TeamMembershipRepositoryImpl({
    required TeamMembershipRemoteDataSource remote,
  }) : _remote = remote;

  final TeamMembershipRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<TeamMembership>>>
      getCurrentUserMemberships() async {
    try {
      final records = await _remote.getCurrentUserMemberships();
      final memberships = <TeamMembership>[];
      for (final record in records) {
        final member = record.member.toEntity();
        if (member.roles.isEmpty) {
          return const Left(
            ServerFailure('An active team membership has no role assignment'),
          );
        }
        final team = record.team.toEntity();
        if (!team.isActive) continue;
        memberships.add(TeamMembership(team: team, member: member));
      }
      memberships.sort(
        (a, b) => a.team.name.toLowerCase().compareTo(b.team.name.toLowerCase()),
      );
      return Right(List<TeamMembership>.unmodifiable(memberships));
    } catch (e) {
      return Left(_failureFor(e));
    }
  }

  @override
  Future<Either<Failure, List<TeamMembership>>> getUserMemberships(
    String userId,
  ) async {
    try {
      final records = await _remote.getUserMemberships(userId);
      final memberships = <TeamMembership>[];
      for (final record in records) {
        final member = record.member.toEntity();
        if (member.roles.isEmpty) continue;
        final team = record.team.toEntity();
        if (!team.isActive) continue;
        memberships.add(TeamMembership(team: team, member: member));
      }
      memberships.sort(
        (a, b) => a.team.name.toLowerCase().compareTo(b.team.name.toLowerCase()),
      );
      return Right(List<TeamMembership>.unmodifiable(memberships));
    } catch (e) {
      return Left(_failureFor(e));
    }
  }

  @override
  Future<Either<Failure, TeamMembership?>> getCurrentUserMembershipForTeam(
    TeamId teamId,
  ) async {
    try {
      final record =
          await _remote.getCurrentUserMembershipForTeam(teamId.value);
      if (record == null) return const Right(null);
      final member = record.member.toEntity();
      if (member.roles.isEmpty) {
        return const Left(
          ServerFailure('An active team membership has no role assignment'),
        );
      }
      return Right(TeamMembership(team: record.team.toEntity(), member: member));
    } catch (e) {
      return Left(_failureFor(e));
    }
  }

  @override
  Future<Either<Failure, List<RosterMember>>> getRoster(TeamId teamId) async {
    try {
      final records = await _remote.getRoster(teamId.value);
      final roster = <RosterMember>[];
      for (final record in records) {
        final member = record.member.toEntity();
        if (member.roles.isEmpty) {
          return const Left(
            ServerFailure('An active roster member has no role assignment'),
          );
        }
        final profile = record.profile;
        final unclaimed = record.unclaimed;
        final displayName = member.playerType == PlayerType.claimed
            ? (profile?['display_name'] as String? ??
                profile?['username'] as String? ??
                'Matchday member')
            : (unclaimed?['display_name'] as String? ?? 'Offline player');
        roster.add(
          RosterMember(
            member: member,
            displayName: displayName,
            username: profile?['username'] as String?,
            profilePhotoUrl: profile?['profile_photo_url'] as String?,
            phoneNumber: unclaimed?['phone_number'] as String?,
          ),
        );
      }
      return Right(List<RosterMember>.unmodifiable(roster));
    } catch (e) {
      return Left(_failureFor(e));
    }
  }

  @override
  Future<Either<Failure, TeamInvite?>> getMyPendingInviteForTeam(
    TeamId teamId,
  ) async {
    try {
      final row = await _remote.getMyPendingInviteForTeam(teamId.value);
      return Right(row == null ? null : _invite(row));
    } catch (e) {
      return Left(_failureFor(e));
    }
  }

  @override
  Future<Either<Failure, List<TeamInvite>>> getTeamPendingInvites(
    TeamId teamId,
  ) async {
    try {
      final rows = await _remote.getTeamPendingInvites(teamId.value);
      return Right(rows.map(_invite).toList(growable: false));
    } catch (e) {
      return Left(_failureFor(e));
    }
  }

  TeamInvite _invite(Map<String, dynamic> row) {
    final inviteeRaw = row['invitee'];
    final inviterRaw = row['inviter'];
    final invitee = inviteeRaw is Map
        ? Map<String, dynamic>.from(inviteeRaw)
        : null;
    final inviter = inviterRaw is Map
        ? Map<String, dynamic>.from(inviterRaw)
        : null;
    return TeamInvite(
      inviteId: row['invite_id'] as String,
      teamId: row['team_id'] as String,
      inviteeId: row['invitee_id'] as String,
      invitedBy: row['invited_by'] as String,
      role: MemberRole.fromWire(row['role'] as String?),
      status: row['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(row['created_at'] as String),
      message: row['message'] as String?,
      jerseyNumber: row['jersey_number'] as int?,
      inviteeName: invitee?['display_name'] as String? ??
          invitee?['username'] as String?,
      inviteeUsername: invitee?['username'] as String?,
      inviteePhotoUrl: invitee?['profile_photo_url'] as String?,
      inviterName: inviter?['display_name'] as String? ??
          inviter?['username'] as String?,
      inviterUsername: inviter?['username'] as String?,
    );
  }

  @override
  Future<Either<Failure, List<TeamJoinRequest>>> getTeamPendingJoinRequests(
    TeamId teamId,
  ) async {
    try {
      final rows = await _remote.getTeamPendingJoinRequests(teamId.value);
      return Right(rows.map((row) {
        final applicantRaw = row['applicant'] ?? row['player'];
        final applicant = applicantRaw is Map
            ? Map<String, dynamic>.from(applicantRaw)
            : null;
        return TeamJoinRequest(
          requestId: row['request_id'] as String,
          teamId: row['team_id'] as String,
          applicantId:
              row['applicant_id'] as String? ?? row['player_id'] as String,
          role: MemberRole.fromWire(row['role'] as String?),
          status: row['status'] as String? ?? 'pending',
          createdAt: DateTime.parse(row['created_at'] as String),
          message: row['message'] as String?,
          applicantName: applicant?['display_name'] as String? ??
              applicant?['username'] as String?,
          applicantUsername: applicant?['username'] as String?,
          applicantPhotoUrl: applicant?['profile_photo_url'] as String?,
        );
      }).toList(growable: false));
    } catch (e) {
      return Left(_failureFor(e));
    }
  }

  @override
  Future<Either<Failure, List<TeamClaimRequest>>> getTeamPendingClaimRequests(
    TeamId teamId,
  ) async {
    try {
      final rows = await _remote.getTeamPendingClaimRequests(teamId.value);
      return Right(rows.map((row) {
        final unclaimedRaw = row['unclaimed'];
        final requesterRaw = row['requester'];
        final unclaimed = unclaimedRaw is Map
            ? Map<String, dynamic>.from(unclaimedRaw)
            : null;
        final requester = requesterRaw is Map
            ? Map<String, dynamic>.from(requesterRaw)
            : null;
        return TeamClaimRequest(
          requestId: row['request_id'] as String,
          unclaimedId: row['unclaimed_id'] as String,
          requesterId: row['requester_id'] as String,
          status: row['status'] as String? ?? 'pending',
          createdAt: DateTime.parse(row['created_at'] as String),
          message: row['message'] as String?,
          unclaimedPlayerName: unclaimed?['display_name'] as String?,
          unclaimedJerseyNumber: unclaimed?['jersey_number'] as int?,
          requesterName: requester?['display_name'] as String? ??
              requester?['username'] as String?,
          requesterUsername: requester?['username'] as String?,
          requesterPhotoUrl: requester?['profile_photo_url'] as String?,
        );
      }).toList(growable: false));
    } catch (e) {
      return Left(_failureFor(e));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> searchUsers(
    String query,
  ) async {
    try {
      return Right(await _remote.searchUsers(query));
    } catch (e) {
      return Left(_failureFor(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> addUnclaimedPlayer({
    required TeamId teamId,
    required PlayerDisplayName displayName,
    String? phoneNumber,
    JerseyNumber? jerseyNumber,
    PlayingRole? playingRole,
    BattingStyle? battingStyle,
    BowlingStyle? bowlingStyle,
  }) =>
      _run(() => _remote.addUnclaimedPlayer(
            teamId: teamId.value,
            displayName: displayName.value,
            phoneNumber: phoneNumber?.trim(),
            jerseyNumber: jerseyNumber?.value,
            playerProfile: {
              if (playingRole != null) 'playing_role': playingRole.wire,
              if (battingStyle != null) 'batting_style': battingStyle.wire,
              if (bowlingStyle != null) 'bowling_style': bowlingStyle.wire,
            },
          ));

  @override
  Future<Either<Failure, Unit>> sendTeamInvite({
    required TeamId teamId,
    required String inviteeId,
    String? message,
    MemberRole role = MemberRole.player,
    int? jerseyNumber,
  }) =>
      _run(() => _remote.sendTeamInvite(
            teamId: teamId.value,
            inviteeId: inviteeId,
            message: message,
            role: role.wire,
            jerseyNumber: jerseyNumber,
          ));

  @override
  Future<Either<Failure, Unit>> setJerseyNumber(
    MembershipId membershipId,
    JerseyNumber? jersey,
  ) =>
      _run(() => _remote.setJerseyNumber(membershipId.value, jersey?.value));

  @override
  Future<Either<Failure, Unit>> assignCaptain(MembershipId membershipId) =>
      _run(() => _remote.assignCaptain(membershipId.value));
  @override
  Future<Either<Failure, Unit>> revokeCaptain(MembershipId membershipId) =>
      _run(() => _remote.revokeCaptain(membershipId.value));
  @override
  Future<Either<Failure, Unit>> promoteToManager(MembershipId membershipId) =>
      _run(() => _remote.promoteToManager(membershipId.value));
  @override
  Future<Either<Failure, Unit>> demoteToPlayer(MembershipId membershipId) =>
      _run(() => _remote.demoteToPlayer(membershipId.value));
  @override
  Future<Either<Failure, Unit>> removeMember(MembershipId membershipId) =>
      _run(() => _remote.removeMember(membershipId.value));
  @override
  Future<Either<Failure, Unit>> leaveTeam(MembershipId membershipId) =>
      _run(() => _remote.leaveTeam(membershipId.value));

  @override
  Future<Either<Failure, Unit>> acceptTeamInvite(String inviteId) =>
      _run(() => _remote.acceptTeamInvite(inviteId));
  @override
  Future<Either<Failure, Unit>> declineTeamInvite(String inviteId) =>
      _run(() => _remote.declineTeamInvite(inviteId));
  @override
  Future<Either<Failure, Unit>> cancelTeamInvite(String inviteId) =>
      _run(() => _remote.cancelTeamInvite(inviteId));
  @override
  Future<Either<Failure, Unit>> acceptJoinRequest(String requestId) =>
      _run(() => _remote.acceptJoinRequest(requestId));
  @override
  Future<Either<Failure, Unit>> declineJoinRequest(String requestId) =>
      _run(() => _remote.declineJoinRequest(requestId));
  @override
  Future<Either<Failure, Unit>> approveClaimRequest(String requestId) =>
      _run(() => _remote.approveClaimRequest(requestId));
  @override
  Future<Either<Failure, Unit>> rejectClaimRequest(String requestId) =>
      _run(() => _remote.rejectClaimRequest(requestId));

  @override
  Future<Either<Failure, Unit>> requestToJoinTeam({
    required TeamId teamId,
    String? message,
  }) =>
      _run(() => _remote.requestToJoinTeam(
            teamId: teamId.value,
            message: message,
          ));

  Future<Either<Failure, Unit>> _run(Future<void> Function() operation) async {
    try {
      await operation();
      return const Right(unit);
    } catch (e) {
      return Left(_failureFor(e));
    }
  }

  Failure _failureFor(Object e) => switch (e) {
        UnauthorizedException(:final message) => AuthFailure(message),
        NotFoundException(:final message) => NotFoundFailure(message),
        ServerException(:final message) => ServerFailure(message),
        _ => UnknownFailure(e.toString()),
      };
}
