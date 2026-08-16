import 'team_member.dart';

/// Represents a pending or resolved team invitation sent to a player.
class TeamInvite {
  const TeamInvite({
    required this.inviteId,
    required this.teamId,
    required this.inviteeId,
    required this.invitedBy,
    required this.role,
    required this.status,
    required this.createdAt,
    this.message,
    this.jerseyNumber,
    this.inviteeName,
    this.inviteeUsername,
    this.inviteePhotoUrl,
  });

  final String inviteId;
  final String teamId;
  final String inviteeId;
  final String invitedBy;
  final MemberRole role;
  final String status;
  final DateTime createdAt;
  final String? message;
  final int? jerseyNumber;
  final String? inviteeName;
  final String? inviteeUsername;
  final String? inviteePhotoUrl;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TeamInvite && other.inviteId == inviteId;

  @override
  int get hashCode => inviteId.hashCode;
}
