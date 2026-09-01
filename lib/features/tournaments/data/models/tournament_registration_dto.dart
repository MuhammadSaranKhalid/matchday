import '../../domain/entities/tournament_registration.dart';

/// Wire-format DTO for `public.tournament_teams` rows.
class TournamentRegistrationDto {
  const TournamentRegistrationDto({
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
  final String registeredAt;
  final String status;
  final List<String> squad;
  final int? seedNumber;
  final String? groupId;
  final String? paymentStatus;
  final String? decidedBy;
  final String? decidedAt;
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
    final profileJson = json['profiles'] as Map<String, dynamic>?;

    return TournamentRegistrationDto(
      registrationId: json['registration_id'] as String,
      tournamentId: json['tournament_id'] as String,
      teamId: json['team_id'] as String,
      registeredBy: json['registered_by'] as String?,
      registeredAt: json['registered_at'] as String? ??
          DateTime.now().toIso8601String(),
      status: json['status'] as String? ?? 'pending',
      squad: (json['squad'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      seedNumber: json['seed_number'] as int?,
      groupId: json['group_id'] as String?,
      paymentStatus: json['payment_status'] as String?,
      decidedBy: json['decided_by'] as String?,
      decidedAt: json['decided_at'] as String?,
      message: json['message'] as String?,
      teamName: teamJson?['team_name'] as String?,
      teamLogoUrl: teamJson?['logo_url'] as String?,
      teamMonogram: teamJson?['logo_monogram'] as String?,
      teamPrimaryColor: teamColors?['primary'] as String?,
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
      squad: squad,
      seedNumber: seedNumber,
      groupId: groupId,
      paymentStatus: paymentStatus,
      decidedBy: decidedBy,
      decidedAt: decidedAt != null ? DateTime.parse(decidedAt!) : null,
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
