import 'team_member.dart';

/// The signed-in user's display/relationship identity on a team.
///
/// IMPORTANT: role identity is not the authorization source of truth.
/// Effective permissions come from the generic RBAC engine (`can` / `team_can`)
/// because each team may override its role-permission matrix. Convenience
/// booleans below are presentation/default-policy hints only and must not gate
/// privileged writes.
enum TeamRelationship {
  owner,
  manager,
  captain,
  player,
  none;

  bool get isStaff => this == owner || this == manager;
  bool get hasMatchAuthority => isStaff || this == captain;
  bool get isMember => this != none;

  bool get canEditRoster => isStaff;
  bool get canInvite => isStaff;
  bool get canPostAsTeam => isStaff;
  bool get canEditTeam => isStaff;
  bool get canRegisterForTournament => isStaff;
  bool get canSendChallenge => isStaff;
  bool get canPickXi => hasMatchAuthority;
  bool get canScore => hasMatchAuthority;
  bool get canAppointScorer => hasMatchAuthority;
  bool get canChangeRoles => isStaff;
  bool get canAppointStaff => this == owner;
  bool get canTransferOwnership => this == owner;
  bool get canDisband => this == owner;
  bool get canLeave => isMember && this != owner;

  bool canGrant(MemberRole target) => switch (this) {
        owner => target != MemberRole.owner,
        manager => target == MemberRole.player || target == MemberRole.captain,
        _ => false,
      };
}

extension TeamMemberRelationshipX on TeamMember {
  /// Multi-role aware relationship. Captain is orthogonal to the
  /// owner/manager/player base rung, so staff wins when both are present.
  TeamRelationship get relationship {
    if (hasRole(MemberRole.owner)) return TeamRelationship.owner;
    if (hasRole(MemberRole.manager)) return TeamRelationship.manager;
    if (hasRole(MemberRole.captain)) return TeamRelationship.captain;
    if (hasRole(MemberRole.player)) return TeamRelationship.player;
    return TeamRelationship.none;
  }
}
