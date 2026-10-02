import '../../domain/entities/tournament_registration.dart';

/// Wire-format DTO for `public.tournament_registrations` rows.
class TournamentRegistrationDto {
  const TournamentRegistrationDto({
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
  final String registeredAt;
  final String status;
  final List<String> squadProposal;
  final String? decidedBy;
  final String? decidedAt;
  final String? decisionReason;
  final String? message;
  final String? teamName;
  final String? teamLogoUrl;
  final String? teamMonogram;
  final String? teamPrimaryColor;
  final String? captainName;
  final String? registeredByName;
  final String createdAt;
  final String updatedAt;

  factory TournamentRegistrationDto.fromJson(Map<String, dynamic> json) {
    final teamJson = json['teams'] as Map<String, dynamic>?;
    final teamColors = teamJson?['team_colors'] as Map<String, dynamic>?;
    final directColors = json['team_colors'] as Map<String, dynamic>?;
    final profileJson = json['profiles'] as Map<String, dynamic>?;

    return TournamentRegistrationDto(
      registrationId: json['registration_id'] as String,
      tournamentId: json['tournament_id'] as String,
      teamId: json['team_id'] as String,
      registeredBy: json['registered_by'] as String?,
      registeredAt: json['registered_at'] as String? ??
          DateTime.now().toIso8601String(),
      status: json['status'] as String? ?? 'pending',
      squadProposal: (json['squad_proposal'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      decidedBy: json['decided_by'] as String?,
      decidedAt: json['decided_at'] as String?,
      decisionReason: json['decision_reason'] as String?,
      message: json['message'] as String?,
      teamName: json['team_name'] as String? ?? teamJson?['team_name'] as String?,
      teamLogoUrl: json['logo_url'] as String? ?? teamJson?['logo_url'] as String?,
      teamMonogram: json['logo_monogram'] as String? ?? teamJson?['logo_monogram'] as String?,
      teamPrimaryColor: directColors?['primary'] as String? ?? teamColors?['primary'] as String?,
      captainName: null,
      registeredByName: profileJson?['display_name'] as String?,
      createdAt: json['created_at'] as String? ??
          DateTime.now().toIso8601String(),
      updatedAt: json['updated_at'] as String? ??
          DateTime.now().toIso8601String(),
    );
  }

  TournamentRegistration toEntity() {
    return TournamentRegistration(
      registrationId: registrationId,
      tournamentId: tournamentId,
      teamId: teamId,
      registeredBy: registeredBy,
      registeredAt: DateTime.parse(registeredAt),
      status: TournamentRegistrationStatus.fromWire(status),
      squadProposal: squadProposal,
      decidedBy: decidedBy,
      decidedAt: decidedAt != null ? DateTime.parse(decidedAt!) : null,
      decisionReason: decisionReason,
      message: message,
      teamName: teamName,
      teamLogoUrl: teamLogoUrl,
      teamMonogram: teamMonogram,
      teamPrimaryColor: teamPrimaryColor,
      captainName: captainName,
      registeredByName: registeredByName,
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
    );
  }
}
