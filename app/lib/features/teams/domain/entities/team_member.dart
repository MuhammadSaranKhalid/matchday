import 'team.dart';

class TeamMember {
  const TeamMember({
    required this.id,
    required this.teamId,
    required this.playerId,
    required this.playerType,
    required this.roles,
    required this.addedBy,
    required this.joinedAt,
    required this.updatedAt,
    this.jerseyNumber,
  });

  final MembershipId id;
  final TeamId teamId;
  final String playerId;
  final PlayerType playerType;
  final Set<String> roles;

  MemberRole get topRole {
    for (final r in [MemberRole.owner, MemberRole.manager, MemberRole.captain]) {
      if (roles.contains(r.wire)) return r;
    }
    return MemberRole.player;
  }

  bool hasRole(MemberRole r) => roles.contains(r.wire);
  bool get isStaff => hasRole(MemberRole.owner) || hasRole(MemberRole.manager);
  bool get hasMatchAuthority => isStaff || hasRole(MemberRole.captain);

  final String? addedBy;
  final DateTime joinedAt;
  final DateTime updatedAt;
  final int? jerseyNumber;

  TeamMember copyWith({
    Set<String>? roles,
    int? jerseyNumber,
    bool clearJersey = false,
    DateTime? updatedAt,
  }) =>
      TeamMember(
        id: id,
        teamId: teamId,
        playerId: playerId,
        playerType: playerType,
        roles: roles ?? this.roles,
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
          other.roles.length == roles.length &&
          other.roles.containsAll(roles) &&
          other.jerseyNumber == jerseyNumber &&
          other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(
      id, teamId, playerId, playerType,
      Object.hashAll(roles.toList()..sort()), jerseyNumber, updatedAt);
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
  player('player'),
  captain('captain'),
  manager('manager'),
  owner('owner');

  const MemberRole(this.wire);
  final String wire;

  static MemberRole fromWire(String? wire) =>
      values.where((r) => r.wire == wire).firstOrNull ?? MemberRole.player;

  bool operator >=(MemberRole other) => index >= other.index;
  bool operator >(MemberRole other) => index > other.index;

  bool get isStaff => this >= MemberRole.manager;
  bool get hasMatchAuthority => this >= MemberRole.captain;

  String get label => switch (this) {
        MemberRole.owner => 'OWNER',
        MemberRole.manager => 'MANAGER',
        MemberRole.captain => 'CAPTAIN',
        MemberRole.player => 'PLAYER',
      };
}
