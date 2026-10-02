import '../../domain/entities/tournament_participant.dart';

/// Wire-format DTO for `public.get_tournament_public_participants` rows.
class TournamentParticipantDto {
  const TournamentParticipantDto({
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
  final String acceptedAt;

  factory TournamentParticipantDto.fromJson(Map<String, dynamic> json) {
    final colors = json['team_colors'] as Map<String, dynamic>?;
    return TournamentParticipantDto(
      entryId: json['entry_id'] as String,
      tournamentId: json['tournament_id'] as String,
      teamId: json['team_id'] as String,
      teamName: json['team_name'] as String? ?? 'Team',
      logoUrl: json['logo_url'] as String?,
      logoMonogram: json['logo_monogram'] as String?,
      teamPrimaryColor: colors?['primary'] as String?,
      status: json['status'] as String? ?? 'accepted',
      acceptedAt: json['accepted_at'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  TournamentParticipant toEntity() {
    return TournamentParticipant(
      entryId: entryId,
      tournamentId: tournamentId,
      teamId: teamId,
      teamName: teamName,
      logoUrl: logoUrl,
      logoMonogram: logoMonogram,
      teamPrimaryColor: teamPrimaryColor,
      status: status,
      acceptedAt: DateTime.parse(acceptedAt),
    );
  }
}
