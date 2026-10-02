import '../../domain/entities/tournament_fixture_slot.dart';

/// Wire-format DTO for `public.tournament_fixture_slots` rows.
class TournamentFixtureSlotDto {
  const TournamentFixtureSlotDto({
    required this.fixtureSlotId,
    required this.fixtureId,
    required this.tournamentId,
    required this.stageId,
    required this.side,
    required this.sourceType,
    this.sourceEntryId,
    this.sourceFixtureId,
    this.sourceGroupId,
    this.sourceStageId,
    this.sourceSeed,
    this.sourceRank,
    this.resolvedEntryId,
    this.resolvedAt,
    this.resolutionReason,
    required this.createdAt,
    required this.updatedAt,
  });

  final String fixtureSlotId;
  final String fixtureId;
  final String tournamentId;
  final String stageId;
  final String side;
  final String sourceType;
  final String? sourceEntryId;
  final String? sourceFixtureId;
  final String? sourceGroupId;
  final String? sourceStageId;
  final int? sourceSeed;
  final int? sourceRank;
  final String? resolvedEntryId;
  final String? resolvedAt;
  final String? resolutionReason;
  final String createdAt;
  final String updatedAt;

  factory TournamentFixtureSlotDto.fromJson(Map<String, dynamic> json) {
    return TournamentFixtureSlotDto(
      fixtureSlotId: json['fixture_slot_id'] as String,
      fixtureId: json['fixture_id'] as String,
      tournamentId: json['tournament_id'] as String,
      stageId: json['stage_id'] as String,
      side: json['side'] as String? ?? 'A',
      sourceType: json['source_type'] as String? ?? 'entry',
      sourceEntryId: json['source_entry_id'] as String?,
      sourceFixtureId: json['source_fixture_id'] as String?,
      sourceGroupId: json['source_group_id'] as String?,
      sourceStageId: json['source_stage_id'] as String?,
      sourceSeed: json['source_seed'] as int?,
      sourceRank: json['source_rank'] as int?,
      resolvedEntryId: json['resolved_entry_id'] as String?,
      resolvedAt: json['resolved_at'] as String?,
      resolutionReason: json['resolution_reason'] as String?,
      createdAt: json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      updatedAt: json['updated_at'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fixture_slot_id': fixtureSlotId,
      'fixture_id': fixtureId,
      'tournament_id': tournamentId,
      'stage_id': stageId,
      'side': side,
      'source_type': sourceType,
      'source_entry_id': sourceEntryId,
      'source_fixture_id': sourceFixtureId,
      'source_group_id': sourceGroupId,
      'source_stage_id': sourceStageId,
      'source_seed': sourceSeed,
      'source_rank': sourceRank,
      'resolved_entry_id': resolvedEntryId,
      'resolved_at': resolvedAt,
      'resolution_reason': resolutionReason,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  TournamentFixtureSlot toEntity() {
    final type = FixtureSlotSourceType.fromWire(sourceType);
    final FixtureSlotSource source = switch (type) {
      FixtureSlotSourceType.entry =>
        FixtureSlotSource.entry(sourceEntryId ?? ''),
      FixtureSlotSourceType.seed =>
        FixtureSlotSource.seed(sourceSeed ?? 0),
      FixtureSlotSourceType.fixtureWinner =>
        FixtureSlotSource.fixtureWinner(sourceFixtureId ?? ''),
      FixtureSlotSourceType.fixtureLoser =>
        FixtureSlotSource.fixtureLoser(sourceFixtureId ?? ''),
      FixtureSlotSourceType.groupRank =>
        FixtureSlotSource.groupRank(
          groupId: sourceGroupId ?? '',
          rank: sourceRank ?? 1,
        ),
      FixtureSlotSourceType.stageRank =>
        FixtureSlotSource.stageRank(
          stageId: sourceStageId ?? '',
          rank: sourceRank ?? 1,
        ),
      FixtureSlotSourceType.bye =>
        const FixtureSlotSource.bye(),
    };

    return TournamentFixtureSlot(
      fixtureSlotId: fixtureSlotId,
      fixtureId: fixtureId,
      tournamentId: tournamentId,
      stageId: stageId,
      side: FixtureSlotSide.fromWire(side),
      source: source,
      resolvedEntryId: resolvedEntryId,
      resolvedAt: resolvedAt != null ? DateTime.tryParse(resolvedAt!) : null,
      resolutionReason: resolutionReason,
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
    );
  }
}
