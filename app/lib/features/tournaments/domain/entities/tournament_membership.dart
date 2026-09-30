import 'package:meta/meta.dart';

/// Status of a tournament staff membership.
enum TournamentMembershipStatus {
  active('active', 'Active'),
  removed('removed', 'Removed'),
  suspended('suspended', 'Suspended');

  const TournamentMembershipStatus(this.wire, this.label);
  final String wire;
  final String label;

  static TournamentMembershipStatus fromWire(String? wire) =>
      values.where((s) => s.wire == wire).firstOrNull ??
      TournamentMembershipStatus.active;
}

/// Normalized Tournament staff membership domain entity.
/// Pure Dart, zero framework dependencies.
@immutable
class TournamentMembership {
  const TournamentMembership({
    required this.id,
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

  final String id;
  final String tournamentId;
  final String? userId;
  final String roleKey;
  final TournamentMembershipStatus status;
  final String? appointedBy;
  final DateTime appointedAt;
  final String? removedBy;
  final DateTime? removedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isActive => status == TournamentMembershipStatus.active;
  bool get isManager => roleKey == 'manager';
  bool get isOwner => roleKey == 'owner';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TournamentMembership &&
          other.id == id &&
          other.tournamentId == tournamentId &&
          other.userId == userId &&
          other.roleKey == roleKey &&
          other.status == status &&
          other.appointedBy == appointedBy &&
          other.appointedAt == appointedAt &&
          other.removedBy == removedBy &&
          other.removedAt == removedAt;

  @override
  int get hashCode => Object.hash(
        id,
        tournamentId,
        userId,
        roleKey,
        status,
        appointedBy,
        appointedAt,
        removedBy,
        removedAt,
      );
}
