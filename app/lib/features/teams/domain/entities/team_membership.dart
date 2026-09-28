import 'package:equatable/equatable.dart';

import 'team.dart';
import 'team_member.dart';
import 'team_relationship.dart';

/// The relationship between one registered Matchday user and one team.
class TeamMembership extends Equatable {
  const TeamMembership({
    required this.team,
    required this.member,
  });

  final Team team;
  final TeamMember member;

  bool get isOwner => member.hasRole(MemberRole.owner);
  bool get isManager => member.hasRole(MemberRole.manager);
  bool get isCaptain => member.hasRole(MemberRole.captain);
  bool get canManage => member.isStaff;
  TeamRelationship get relationship => member.relationship;

  @override
  List<Object?> get props => [team, member];
}
