import '../../domain/entities/tournament_stage_entry.dart';

/// Wire-format DTO for `public.tournament_stage_entries` rows.
class TournamentStageEntryDto {
  const TournamentStageEntryDto({
    required this.stageEntryId,
    required this.stageId,
    required this.entryId,
    required this.tournamentId,
    this.groupId,
    this.seed,
    required this.status,
    this.sourceStageId,
    this.qualificationSource,
    required this.enteredAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String stageEntryId;
  final String stageId;
  final String entryId;
  final String tournamentId;
  final String? groupId;
  final int? seed;
  final String status;
  final String? sourceStageId;
  final String? qualificationSource;
  final String enteredAt;
  final String createdAt;
  final String updatedAt;

  factory TournamentStageEntryDto.fromJson(Map<String, dynamic> json) {
    return TournamentStageEntryDto(
      stageEntryId: json['stage_entry_id'] as String,
      stageId: json['stage_id'] as String,
      entryId: json['entry_id'] as String,
      tournamentId: json['tournament_id'] as String,
      groupId: json['group_id'] as String?,
      seed: json['seed'] as int?,
      status: json['status'] as String? ?? 'active',
      sourceStageId: json['source_stage_id'] as String?,
      qualificationSource: json['qualification_source'] as String?,
      enteredAt: json['entered_at'] as String? ?? DateTime.now().toIso8601String(),
      createdAt: json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      updatedAt: json['updated_at'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stage_entry_id': stageEntryId,
      'stage_id': stageId,
      'entry_id': entryId,
      'tournament_id': tournamentId,
      'group_id': groupId,
      'seed': seed,
      'status': status,
      'source_stage_id': sourceStageId,
      'qualification_source': qualificationSource,
      'entered_at': enteredAt,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  TournamentStageEntry toEntity() {
    return TournamentStageEntry(
      stageEntryId: stageEntryId,
      stageId: stageId,
      entryId: entryId,
      tournamentId: tournamentId,
      groupId: groupId,
      seed: seed,
      status: TournamentStageEntryStatus.fromWire(status),
      sourceStageId: sourceStageId,
      qualificationSource: qualificationSource,
      enteredAt: DateTime.parse(enteredAt),
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
    );
  }
}
