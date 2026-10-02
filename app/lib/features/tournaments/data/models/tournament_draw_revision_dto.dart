import '../../domain/entities/tournament_draw_revision.dart';

/// Wire-format DTO for `public.tournament_draw_revisions` rows.
class TournamentDrawRevisionDto {
  const TournamentDrawRevisionDto({
    required this.drawRevisionId,
    required this.stageId,
    required this.tournamentId,
    required this.revisionNumber,
    required this.status,
    required this.basedOnEntryRevision,
    this.planSnapshot = const {},
    this.revisionReason,
    this.createdBy,
    required this.createdAt,
    this.publishedBy,
    this.publishedAt,
  });

  final String drawRevisionId;
  final String stageId;
  final String tournamentId;
  final int revisionNumber;
  final String status;
  final int basedOnEntryRevision;
  final Map<String, dynamic> planSnapshot;
  final String? revisionReason;
  final String? createdBy;
  final String createdAt;
  final String? publishedBy;
  final String? publishedAt;

  factory TournamentDrawRevisionDto.fromJson(Map<String, dynamic> json) {
    return TournamentDrawRevisionDto(
      drawRevisionId: json['draw_revision_id'] as String,
      stageId: json['stage_id'] as String,
      tournamentId: json['tournament_id'] as String,
      revisionNumber: json['revision_number'] as int? ?? 1,
      status: json['status'] as String? ?? 'draft',
      basedOnEntryRevision: json['based_on_entry_revision'] as int? ?? 1,
      planSnapshot: (json['plan_snapshot'] as Map<String, dynamic>?) ?? const {},
      revisionReason: json['revision_reason'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      publishedBy: json['published_by'] as String?,
      publishedAt: json['published_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'draw_revision_id': drawRevisionId,
      'stage_id': stageId,
      'tournament_id': tournamentId,
      'revision_number': revisionNumber,
      'status': status,
      'based_on_entry_revision': basedOnEntryRevision,
      'plan_snapshot': planSnapshot,
      'revision_reason': revisionReason,
      'created_by': createdBy,
      'created_at': createdAt,
      'published_by': publishedBy,
      'published_at': publishedAt,
    };
  }

  TournamentDrawRevision toEntity() {
    return TournamentDrawRevision(
      drawRevisionId: drawRevisionId,
      stageId: stageId,
      tournamentId: tournamentId,
      revisionNumber: revisionNumber,
      status: TournamentDrawRevisionStatus.fromWire(status),
      basedOnEntryRevision: basedOnEntryRevision,
      planSnapshot: planSnapshot,
      revisionReason: revisionReason,
      createdBy: createdBy,
      createdAt: DateTime.parse(createdAt),
      publishedBy: publishedBy,
      publishedAt: publishedAt != null ? DateTime.tryParse(publishedAt!) : null,
    );
  }
}
