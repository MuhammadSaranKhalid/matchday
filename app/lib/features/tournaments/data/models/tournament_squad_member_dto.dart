import '../../domain/entities/tournament_squad_member.dart';

/// Wire DTO for `public.tournament_squad_members` rows.
class TournamentSquadMemberDto {
  const TournamentSquadMemberDto({
    required this.squadMemberId,
    required this.entryId,
    required this.tournamentId,
    this.userId,
    this.unclaimedId,
    required this.membershipStatus,
    required this.addedAt,
    required this.createdAt,
    required this.updatedAt,
    this.addedBy,
    this.removedAt,
    this.removedBy,
    this.amendmentReason,
    this.displayName,
    this.username,
    this.avatarUrl,
  });

  final String squadMemberId;
  final String entryId;
  final String tournamentId;
  final String? userId;
  final String? unclaimedId;
  final String membershipStatus;
  final String? addedBy;
  final String addedAt;
  final String? removedAt;
  final String? removedBy;
  final String? amendmentReason;
  final String createdAt;
  final String updatedAt;
  final String? displayName;
  final String? username;
  final String? avatarUrl;

  factory TournamentSquadMemberDto.fromJson(Map<String, dynamic> json) {
    final profileJson = json['profiles'] as Map<String, dynamic>?;
    final unclaimedJson = json['unclaimed_players'] as Map<String, dynamic>?;
    return TournamentSquadMemberDto(
      squadMemberId: json['squad_member_id'] as String,
      entryId: json['entry_id'] as String,
      tournamentId: json['tournament_id'] as String,
      userId: json['user_id'] as String?,
      unclaimedId: json['unclaimed_id'] as String?,
      membershipStatus: json['membership_status'] as String? ?? 'active',
      addedBy: json['added_by'] as String?,
      addedAt: json['added_at'] as String? ?? DateTime.now().toIso8601String(),
      removedAt: json['removed_at'] as String?,
      removedBy: json['removed_by'] as String?,
      amendmentReason: json['amendment_reason'] as String?,
      createdAt: json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      updatedAt: json['updated_at'] as String? ?? DateTime.now().toIso8601String(),
      displayName: profileJson?['display_name'] as String? ?? unclaimedJson?['display_name'] as String?,
      username: profileJson?['username'] as String?,
      avatarUrl: profileJson?['avatar_url'] as String?,
    );
  }

  TournamentSquadMember toEntity() => TournamentSquadMember(
        squadMemberId: squadMemberId,
        entryId: entryId,
        tournamentId: tournamentId,
        userId: userId,
        unclaimedId: unclaimedId,
        membershipStatus:
            TournamentSquadMembershipStatus.fromWire(membershipStatus),
        addedBy: addedBy,
        addedAt: DateTime.parse(addedAt),
        removedAt: removedAt != null ? DateTime.parse(removedAt!) : null,
        removedBy: removedBy,
        amendmentReason: amendmentReason,
        createdAt: DateTime.parse(createdAt),
        updatedAt: DateTime.parse(updatedAt),
        displayName: displayName,
        username: username,
        avatarUrl: avatarUrl,
      );
}
