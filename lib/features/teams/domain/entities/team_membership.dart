import 'package:equatable/equatable.dart';

import 'team.dart';
import 'team_member.dart';

/// The relationship between one registered Matchday user and one team.
///
/// This is a domain concept, not a "My Teams" UI model. The membership owns
/// the user's roles; [team] owns the team's identity and profile data.
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

  /// Administrative authority for team identity / roster management.
  ///
  /// Captaincy alone is deliberately not administrative authority.
  bool get canManage => member.isStaff;

  @override
  List<Object?> get props => [team, member];
}
