import 'package:equatable/equatable.dart';

/// Membership status of a player in a tournament entry squad.
enum TournamentSquadMembershipStatus {
  active('active', 'Active'),
  removed('removed', 'Removed');

  const TournamentSquadMembershipStatus(this.wire, this.label);
  final String wire;
  final String label;

  static TournamentSquadMembershipStatus fromWire(String? wire) =>
      values.where((s) => s.wire == wire).firstOrNull ??
      TournamentSquadMembershipStatus.active;
}

/// A player eligible to represent an Entry in a Tournament.
class TournamentSquadMember extends Equatable {
  const TournamentSquadMember({
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
  final TournamentSquadMembershipStatus membershipStatus;
  final String? addedBy;
  final DateTime addedAt;
  final DateTime? removedAt;
  final String? removedBy;
  final String? amendmentReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Enriched presentation fields
  final String? displayName;
  final String? username;
  final String? avatarUrl;

  bool get isActive => membershipStatus == TournamentSquadMembershipStatus.active;
  bool get isClaimed => userId != null;
  String get playerId => userId ?? unclaimedId ?? '';

  @override
  List<Object?> get props => [
        squadMemberId,
        entryId,
        tournamentId,
        userId,
        unclaimedId,
        membershipStatus,
        addedBy,
        addedAt,
        removedAt,
        removedBy,
        amendmentReason,
        createdAt,
        updatedAt,
      ];
}
