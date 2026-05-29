// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MatchDto _$MatchDtoFromJson(Map<String, dynamic> json) => _MatchDto(
  matchId: json['match_id'] as String,
  teamAId: json['team_a_id'] as String,
  teamBId: json['team_b_id'] as String,
  teamACaptain: json['team_a_captain'] as String?,
  teamBCaptain: json['team_b_captain'] as String?,
  format: json['format'] as Map<String, dynamic>,
  venue: json['venue'] as String?,
  scheduledStartTime: json['scheduled_start_time'] as String?,
  actualStartTime: json['actual_start_time'] as String?,
  result: json['result'] as Map<String, dynamic>?,
  status: json['status'] as String? ?? 'scheduled',
  tossWonBy: json['toss_won_by'] as String?,
  tossDecision: json['toss_decision'] as String?,
  tossFace: json['toss_face'] as String?,
  startPhase: json['start_phase'] as String? ?? 'toss',
  openersSubmittedBy: json['openers_submitted_by'] as String?,
  openersSubmittedAt: json['openers_submitted_at'] as String?,
  createdBy: json['created_by'] as String?,
  createdAt: json['created_at'] as String,
);

Map<String, dynamic> _$MatchDtoToJson(_MatchDto instance) => <String, dynamic>{
  'match_id': instance.matchId,
  'team_a_id': instance.teamAId,
  'team_b_id': instance.teamBId,
  'team_a_captain': instance.teamACaptain,
  'team_b_captain': instance.teamBCaptain,
  'format': instance.format,
  'venue': instance.venue,
  'scheduled_start_time': instance.scheduledStartTime,
  'actual_start_time': instance.actualStartTime,
  'result': instance.result,
  'status': instance.status,
  'toss_won_by': instance.tossWonBy,
  'toss_decision': instance.tossDecision,
  'toss_face': instance.tossFace,
  'start_phase': instance.startPhase,
  'openers_submitted_by': instance.openersSubmittedBy,
  'openers_submitted_at': instance.openersSubmittedAt,
  'created_by': instance.createdBy,
  'created_at': instance.createdAt,
};
