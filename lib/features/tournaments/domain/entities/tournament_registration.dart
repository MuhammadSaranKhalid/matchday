import 'package:meta/meta.dart';

/// Registration status for a team in a tournament.
enum TournamentRegistrationStatus {
  pending('pending', 'Pending Decision'),
  approved('approved', 'Approved'),
  rejected('rejected', 'Declined'),
  withdrawn('withdrawn', 'Withdrawn');

  const TournamentRegistrationStatus(this.wire, this.label);
  final String wire;
  final String label;

  static TournamentRegistrationStatus fromWire(String? wire) =>
      values.where((s) => s.wire == wire).firstOrNull ??
      TournamentRegistrationStatus.pending;
}

/// A team registration record for a tournament.
@immutable
class TournamentRegistration {
  const TournamentRegistration({
    required this.registrationId,
    required this.tournamentId,
    required this.teamId,
    required this.registeredAt,
    required this.status,
    required this.squad,
    required this.createdAt,
    required this.updatedAt,
    this.registeredBy,
    this.seedNumber,
    this.groupId,
    this.paymentStatus,
    this.decidedBy,
    this.decidedAt,
    this.message,
    this.teamName,
    this.teamLogoUrl,
    this.teamMonogram,
    this.teamPrimaryColor,
    this.captainName,
    this.registeredByName,
  });

  final String registrationId;
  final String tournamentId;
  final String teamId;
  final String? registeredBy;
  final DateTime registeredAt;
  final TournamentRegistrationStatus status;
  final List<String> squad;
  final int? seedNumber;
  final String? groupId;
  final String? paymentStatus;
  final String? decidedBy;
  final DateTime? decidedAt;
  final String? message;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Enriched presentation fields
  final String? teamName;
  final String? teamLogoUrl;
  final String? teamMonogram;
  final String? teamPrimaryColor;
  final String? captainName;
  final String? registeredByName;

  bool get isApproved => status == TournamentRegistrationStatus.approved;
  bool get isPending => status == TournamentRegistrationStatus.pending;
  bool get isPaid =>
      paymentStatus != null &&
      paymentStatus!.toLowerCase().contains('paid') &&
      !paymentStatus!.toLowerCase().contains('unpaid');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TournamentRegistration &&
          other.registrationId == registrationId &&
          other.tournamentId == tournamentId &&
          other.teamId == teamId &&
          other.status == status &&
          other.seedNumber == seedNumber &&
          other.paymentStatus == paymentStatus &&
          other.message == message;

  @override
  int get hashCode => Object.hash(
        registrationId,
        tournamentId,
        teamId,
        status,
        seedNumber,
        paymentStatus,
      );
}
