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
    this.squadProposal = const [],
    required this.createdAt,
    required this.updatedAt,
    this.registeredBy,
    this.decidedBy,
    this.decidedAt,
    this.decisionReason,
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
  final List<String> squadProposal;

  /// Convenience getter for submitted squad proposal.
  List<String> get squad => squadProposal;

  final String? decidedBy;
  final DateTime? decidedAt;

  /// Why the organiser declined, in their own words. Distinct from [message],
  /// which is the note the *manager* submitted with the application.
  final String? decisionReason;

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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TournamentRegistration &&
          other.registrationId == registrationId &&
          other.tournamentId == tournamentId &&
          other.teamId == teamId &&
          other.status == status &&
          other.decisionReason == decisionReason &&
          other.message == message;

  @override
  int get hashCode => Object.hash(
        registrationId,
        tournamentId,
        teamId,
        status,
        decisionReason,
        message,
      );
}
