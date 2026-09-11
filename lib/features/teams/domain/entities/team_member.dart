import 'team.dart';

/// A roster membership linking a player (claimed or unclaimed) to a team.
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

  /// References profiles.user_id (claimed) or unclaimed_players.id (unclaimed).
  final String playerId;
  final PlayerType playerType;
  /// Every role this member holds. A member can be owner AND captain — the
  /// case the old single `role` column could not represent at all.
  ///
  /// Role KEYS, not a closed enum: roles are rows in `public.roles` now, so a
  /// new one ("Coach") must not be silently coerced to `player`. [MemberRole]
  /// still exists for the four the UI reasons about; unknown keys survive here
  /// as strings and render from their catalogue name.
  final Set<String> roles;

  /// The highest-ranked role this member holds, for a single-chip display.
  MemberRole get topRole {
    for (final r in [MemberRole.owner, MemberRole.manager, MemberRole.captain]) {
      if (roles.contains(r.wire)) return r;
    }
    return MemberRole.player;
  }

  bool hasRole(MemberRole r) => roles.contains(r.wire);

  /// Mirrors the SQL predicates. Display only — the server is the authority.
  bool get isStaff => hasRole(MemberRole.owner) || hasRole(MemberRole.manager);
  bool get hasMatchAuthority => isStaff || hasRole(MemberRole.captain);

  /// The user who added this member. Guaranteed non-null — enforced by the
  /// `team_members.added_by NOT NULL` constraint.
  /// Who added this member, or null once that person deletes their account.
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

/// The team authority ladder — mirrors the `member_role` Postgres enum, in the
/// same ascending order, because that order IS the ladder on both sides
/// (`role >= 'manager'` in SQL, `index >= manager.index` here).
///
/// See docs/team-roles-design.md. Before 2026-09-10 this enum was
/// captain/vice_captain/wicket_keeper/player and granted nothing — authority
/// lived in a separate `teams.managers` array that ignored it, so a captain
/// could not manage the team they captained.
///
/// `wicketKeeper` is deliberately absent: a keeper can also be the captain, so
/// it can never be a rung. It lives on the player's profile (career fact) and
/// on `match_players.role` (this match's XI). `viceCaptain` is dropped for v1.
enum MemberRole {
  player('player'),
  captain('captain'),
  manager('manager'),
  owner('owner');

  const MemberRole(this.wire);
  final String wire;

  static MemberRole fromWire(String? wire) =>
      values.where((r) => r.wire == wire).firstOrNull ?? MemberRole.player;

  /// Ladder comparison. Declaration order is power order, so `index` is rank.
  bool operator >=(MemberRole other) => index >= other.index;
  bool operator >(MemberRole other) => index > other.index;

  /// The two SQL predicates, mirrored so the UI can gate without a round trip.
  bool get isStaff => this >= MemberRole.manager;   // is_team_manager()
  bool get hasMatchAuthority => this >= MemberRole.captain; // is_team_captain()

  /// What this rung is called in the UI. Uppercase for the mono role pill.
  String get label => switch (this) {
        MemberRole.owner => 'OWNER',
        MemberRole.manager => 'MANAGER',
        MemberRole.captain => 'CAPTAIN',
        MemberRole.player => 'PLAYER',
      };
}
