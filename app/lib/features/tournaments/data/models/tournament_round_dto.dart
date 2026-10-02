import '../../domain/entities/tournament_round.dart';

/// Wire-format DTO for `public.tournament_rounds` rows.
class TournamentRoundDto {
  const TournamentRoundDto({
    required this.roundId,
    required this.stageId,
    required this.tournamentId,
    this.groupId,
    required this.roundNumber,
    required this.label,
    required this.createdAt,
    required this.updatedAt,
  });

  final String roundId;
  final String stageId;
  final String tournamentId;
  final String? groupId;
  final int roundNumber;
  final String label;
  final String createdAt;
  final String updatedAt;

  factory TournamentRoundDto.fromJson(Map<String, dynamic> json) {
    return TournamentRoundDto(
      roundId: json['round_id'] as String,
      stageId: json['stage_id'] as String,
      tournamentId: json['tournament_id'] as String,
      groupId: json['group_id'] as String?,
      roundNumber: json['round_number'] as int? ?? 1,
      label: json['label'] as String? ?? 'Round',
      createdAt: json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      updatedAt: json['updated_at'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'round_id': roundId,
      'stage_id': stageId,
      'tournament_id': tournamentId,
      'group_id': groupId,
      'round_number': roundNumber,
      'label': label,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  TournamentRound toEntity() {
    return TournamentRound(
      roundId: roundId,
      stageId: stageId,
      tournamentId: tournamentId,
      groupId: groupId,
      roundNumber: roundNumber,
      label: label,
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
    );
  }
}
