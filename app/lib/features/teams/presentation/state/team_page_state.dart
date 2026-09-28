import '../../../matches/domain/entities/match.dart';
import '../../domain/entities/roster_member.dart';
import '../../domain/entities/team.dart';
import '../../domain/entities/team_invite.dart';
import '../../domain/entities/team_membership.dart';
import '../../domain/entities/team_relationship.dart';

class TeamPageState {
  const TeamPageState({
    required this.team,
    required this.roster,
    required this.matches,
    this.membership,
    this.pendingInvite,
    this.opponentNames = const {},
  });

  final Team team;
  final TeamMembership? membership;
  final List<RosterMember> roster;
  final List<Match> matches;
  final TeamInvite? pendingInvite;
  final Map<String, String> opponentNames;

  TeamRelationship get relationship =>
      membership?.relationship ?? TeamRelationship.none;

  bool get canManage => relationship.isStaff && team.isActive;
  bool get canPostAsTeam => relationship.canPostAsTeam && team.isActive;
  bool get canRequestJoin =>
      relationship == TeamRelationship.none &&
      pendingInvite == null &&
      team.privacy == TeamPrivacy.public &&
      team.isActive;
  bool get canFollow =>
      relationship == TeamRelationship.none &&
      team.privacy == TeamPrivacy.public &&
      team.isActive;
  bool get canLeave => relationship.canLeave && team.isActive;
  bool get canChangeStatus => relationship.canDisband;
}
