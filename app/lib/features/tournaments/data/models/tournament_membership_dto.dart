import '../../domain/entities/tournament_membership.dart';

/// Wire DTO for `public.tournament_memberships` rows.
class TournamentMembershipDto {
  const TournamentMembershipDto({
    required this.membershipId,
    required this.tournamentId,
    this.userId,
    required this.roleKey,
    required this.status,
    required this.appointedAt,
    required this.createdAt,
    required this.updatedAt,
    this.appointedBy,
    this.removedBy,
    this.removedAt,
  });

  final String membershipId;
  final String tournamentId;
  final String? userId;
  final String roleKey;
  final String status;
  final String? appointedBy;
  final String appointedAt;
  final String? removedBy;
  final String? removedAt;
  final String createdAt;
  final String updatedAt;

  factory TournamentMembershipDto.fromJson(Map<String, dynamic> json) {
    return TournamentMembershipDto(
      membershipId: json['membership_id'] as String,
      tournamentId: json['tournament_id'] as String,
      userId: json['user_id'] as String?,
      roleKey: json['role_key'] as String? ?? 'manager',
      status: json['status'] as String? ?? 'active',
      appointedBy: json['appointed_by'] as String?,
      appointedAt: json['appointed_at'] as String? ??
          DateTime.now().toIso8601String(),
      removedBy: json['removed_by'] as String?,
      removedAt: json['removed_at'] as String?,
      createdAt: json['created_at'] as String? ??
          DateTime.now().toIso8601String(),
      updatedAt: json['updated_at'] as String? ??
          DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() => {
        'membership_id': membershipId,
        'tournament_id': tournamentId,
        'user_id': userId,
        'role_key': roleKey,
        'status': status,
        if (appointedBy != null) 'appointed_by': appointedBy,
        'appointed_at': appointedAt,
        if (removedBy != null) 'removed_by': removedBy,
        if (removedAt != null) 'removed_at': removedAt,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  TournamentMembership toEntity() {
    return TournamentMembership(
      id: membershipId,
      tournamentId: tournamentId,
      userId: userId,
      roleKey: roleKey,
      status: TournamentMembershipStatus.fromWire(status),
      appointedBy: appointedBy,
      appointedAt: DateTime.parse(appointedAt),
      removedBy: removedBy,
      removedAt: removedAt != null ? DateTime.tryParse(removedAt!) : null,
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
    );
  }
}
