import 'team.dart';

/// A roster membership linking a player (claimed or unclaimed) to a team.
class TeamMember {
  const TeamMember({
    required this.id,
    required this.teamId,
    required this.playerId,
    required this.playerType,
    required this.role,
    required this.addedBy,
    required this.joinedAt,
    required this.updatedAt,
    this.jerseyNumber,
  });

  final MembershipId id;
  final TeamId teamId;

  /// References profiles.user_id (claimed) or unclaimed_players.id (unclaimed).
  final String playerId;
  final PlayerType playerType;
  final MemberRole role;

  /// The user who added this member. Guaranteed non-null — enforced by the
  /// `team_members.added_by NOT NULL` constraint.
  /// Who added this member, or null once that person deletes their account.
  final String? addedBy;
  final DateTime joinedAt;
  final DateTime updatedAt;
  final int? jerseyNumber;

  TeamMember copyWith({
    MemberRole? role,
    int? jerseyNumber,
    bool clearJersey = false,
    DateTime? updatedAt,
  }) =>
      TeamMember(
        id: id,
        teamId: teamId,
        playerId: playerId,
        playerType: playerType,
        role: role ?? this.role,
        addedBy: addedBy,
        joinedAt: joinedAt,
        updatedAt: updatedAt ?? this.updatedAt,
        jerseyNumber: clearJersey ? null : (jerseyNumber ?? this.jerseyNumber),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TeamMember &&
          other.id == id &&
          other.teamId == teamId &&
          other.playerId == playerId &&
          other.playerType == playerType &&
          other.role == role &&
          other.jerseyNumber == jerseyNumber &&
          other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(
      id, teamId, playerId, playerType, role, jerseyNumber, updatedAt);
}

class MembershipId {
  const MembershipId(this.value);
  final String value;
  @override
  bool operator ==(Object other) =>
      other is MembershipId && other.value == value;
  @override
  int get hashCode => value.hashCode;
  @override
  String toString() => value;
}

enum PlayerType {
  claimed('claimed'),
  unclaimed('unclaimed');

  const PlayerType(this.wire);
  final String wire;

  static PlayerType fromWire(String? wire) =>
      values.where((t) => t.wire == wire).firstOrNull ?? PlayerType.unclaimed;
}

enum MemberRole {
  captain('captain'),
  viceCaptain('vice_captain'),
  wicketKeeper('wicket_keeper'),
  player('player');

  const MemberRole(this.wire);
  final String wire;

  static MemberRole fromWire(String? wire) =>
      values.where((r) => r.wire == wire).firstOrNull ?? MemberRole.player;
}
