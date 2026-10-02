import '../../domain/entities/tournament_group.dart';

/// Wire-format DTO for `public.tournament_groups` rows.
class TournamentGroupDto {
  const TournamentGroupDto({
    required this.groupId,
    required this.stageId,
    required this.tournamentId,
    required this.sequence,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  final String groupId;
  final String stageId;
  final String tournamentId;
  final int sequence;
  final String name;
  final String createdAt;
  final String updatedAt;

  factory TournamentGroupDto.fromJson(Map<String, dynamic> json) {
    return TournamentGroupDto(
      groupId: json['group_id'] as String,
      stageId: json['stage_id'] as String,
      tournamentId: json['tournament_id'] as String,
      sequence: json['sequence'] as int? ?? 1,
      name: json['name'] as String? ?? 'Group',
      createdAt: json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      updatedAt: json['updated_at'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'group_id': groupId,
      'stage_id': stageId,
      'tournament_id': tournamentId,
      'sequence': sequence,
      'name': name,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  TournamentGroup toEntity() {
    return TournamentGroup(
      groupId: groupId,
      stageId: stageId,
      tournamentId: tournamentId,
      sequence: sequence,
      name: name,
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
    );
  }
}
