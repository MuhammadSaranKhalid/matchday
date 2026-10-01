import '../../domain/entities/tournament_entry.dart';

/// Wire DTO for `public.tournament_entries` rows.
class TournamentEntryDto {
  const TournamentEntryDto({
    required this.entryId,
    required this.tournamentId,
    required this.teamId,
    required this.status,
    required this.entrySource,
    required this.squadState,
    required this.createdAt,
    required this.updatedAt,
    this.registrationId,
    this.acceptedBy,
    this.acceptedAt,
    this.withdrawnAt,
    this.withdrawalReason,
    this.disqualifiedAt,
    this.disqualificationReason,
    this.squadFrozenAt,
    this.teamName,
    this.teamLogoUrl,
  });

  final String entryId;
  final String tournamentId;
  final String teamId;
  final String status;
  final String entrySource;
  final String squadState;
  final String? registrationId;
  final String? acceptedBy;
  final String? acceptedAt;
  final String? withdrawnAt;
  final String? withdrawalReason;
  final String? disqualifiedAt;
  final String? disqualificationReason;
  final String? squadFrozenAt;
  final String createdAt;
  final String updatedAt;
  final String? teamName;
  final String? teamLogoUrl;

  factory TournamentEntryDto.fromJson(Map<String, dynamic> json) {
    final teamJson = json['teams'] as Map<String, dynamic>?;
    return TournamentEntryDto(
      entryId: json['entry_id'] as String,
      tournamentId: json['tournament_id'] as String,
      teamId: json['team_id'] as String,
      status: json['status'] as String? ?? 'active',
      entrySource: json['entry_source'] as String? ?? 'application',
      squadState: json['squad_state'] as String? ?? 'editable',
      registrationId: json['registration_id'] as String?,
      acceptedBy: json['accepted_by'] as String?,
      acceptedAt: json['accepted_at'] as String?,
      withdrawnAt: json['withdrawn_at'] as String?,
      withdrawalReason: json['withdrawal_reason'] as String?,
      disqualifiedAt: json['disqualified_at'] as String?,
      disqualificationReason: json['disqualification_reason'] as String?,
      squadFrozenAt: json['squad_frozen_at'] as String?,
      createdAt: json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      updatedAt: json['updated_at'] as String? ?? DateTime.now().toIso8601String(),
      teamName: teamJson?['team_name'] as String?,
      teamLogoUrl: teamJson?['logo_url'] as String?,
    );
  }

  TournamentEntry toEntity() => TournamentEntry(
        entryId: entryId,
        tournamentId: tournamentId,
        teamId: teamId,
        status: TournamentEntryStatus.fromWire(status),
        entrySource: entrySource,
        squadState: TournamentSquadState.fromWire(squadState),
        registrationId: registrationId,
        acceptedBy: acceptedBy,
        acceptedAt: acceptedAt != null ? DateTime.parse(acceptedAt!) : null,
        withdrawnAt: withdrawnAt != null ? DateTime.parse(withdrawnAt!) : null,
        withdrawalReason: withdrawalReason,
        disqualifiedAt:
            disqualifiedAt != null ? DateTime.parse(disqualifiedAt!) : null,
        disqualificationReason: disqualificationReason,
        squadFrozenAt:
            squadFrozenAt != null ? DateTime.parse(squadFrozenAt!) : null,
        createdAt: DateTime.parse(createdAt),
        updatedAt: DateTime.parse(updatedAt),
        teamName: teamName,
        teamLogoUrl: teamLogoUrl,
      );
}
