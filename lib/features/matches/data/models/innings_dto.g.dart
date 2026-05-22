// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'innings_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_InningsDto _$InningsDtoFromJson(Map<String, dynamic> json) => _InningsDto(
  inningsId: json['innings_id'] as String,
  matchId: json['match_id'] as String,
  inningsNumber: (json['innings_number'] as num).toInt(),
  battingTeamId: json['batting_team_id'] as String,
  bowlingTeamId: json['bowling_team_id'] as String,
  totalRuns: (json['total_runs'] as num?)?.toInt() ?? 0,
  totalWickets: (json['total_wickets'] as num?)?.toInt() ?? 0,
  totalOvers: json['total_overs'] as num? ?? 0,
  totalBallsFaced: (json['total_balls_faced'] as num?)?.toInt() ?? 0,
  target: (json['target'] as num?)?.toInt(),
  status: json['status'] as String? ?? 'in_progress',
  currentStrikerId: json['current_striker_id'] as String?,
  currentNonStrikerId: json['current_non_striker_id'] as String?,
  currentBowlerId: json['current_bowler_id'] as String?,
);

Map<String, dynamic> _$InningsDtoToJson(_InningsDto instance) =>
    <String, dynamic>{
      'innings_id': instance.inningsId,
      'match_id': instance.matchId,
      'innings_number': instance.inningsNumber,
      'batting_team_id': instance.battingTeamId,
      'bowling_team_id': instance.bowlingTeamId,
      'total_runs': instance.totalRuns,
      'total_wickets': instance.totalWickets,
      'total_overs': instance.totalOvers,
      'total_balls_faced': instance.totalBallsFaced,
      'target': instance.target,
      'status': instance.status,
      'current_striker_id': instance.currentStrikerId,
      'current_non_striker_id': instance.currentNonStrikerId,
      'current_bowler_id': instance.currentBowlerId,
    };
