import 'package:equatable/equatable.dart';

/// Public participant representation of an accepted tournament entry.
///
/// Strips all private registration, contact, and audit details while
/// providing the necessary visual team identity for brackets, participant lists,
/// and match scorecards.
class TournamentParticipant extends Equatable {
  const TournamentParticipant({
    required this.entryId,
    required this.tournamentId,
    required this.teamId,
    required this.teamName,
    this.logoUrl,
    this.logoMonogram,
    this.teamPrimaryColor,
    required this.status,
    required this.acceptedAt,
  });

  final String entryId;
  final String tournamentId;
  final String teamId;
  final String teamName;
  final String? logoUrl;
  final String? logoMonogram;
  final String? teamPrimaryColor;
  final String status;
  final DateTime acceptedAt;

  @override
  List<Object?> get props => [
        entryId,
        tournamentId,
        teamId,
        teamName,
        logoUrl,
        logoMonogram,
        teamPrimaryColor,
        status,
        acceptedAt,
      ];
}
