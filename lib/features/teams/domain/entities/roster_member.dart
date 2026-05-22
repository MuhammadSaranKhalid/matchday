import 'team_member.dart';

/// A roster row for display: the membership joined with the player's resolved
/// display name. The local data source builds this by joining team_members
/// with unclaimed_players (Phase 1 players are all unclaimed).
class RosterMember {
  const RosterMember({required this.member, required this.displayName});

  final TeamMember member;
  final String displayName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RosterMember &&
          other.member == member &&
          other.displayName == displayName;

  @override
  int get hashCode => Object.hash(member, displayName);
}
