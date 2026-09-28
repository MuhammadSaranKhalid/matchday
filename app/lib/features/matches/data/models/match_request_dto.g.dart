// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_request_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MatchRequestDto _$MatchRequestDtoFromJson(Map<String, dynamic> json) =>
    _MatchRequestDto(
      requestId: json['request_id'] as String,
      fromTeamId: json['from_team_id'] as String,
      toTeamId: json['to_team_id'] as String?,
      requestedBy: json['requested_by'] as String,
      proposedStartTime: json['proposed_start_time'] as String?,
      proposedVenue: json['proposed_venue'] as String?,
      proposedFormatCode: json['proposed_format_code'] as String?,
      proposedFormat: json['proposed_format'] as Map<String, dynamic>?,
      message: json['message'] as String?,
      playersPerSide: (json['players_per_side'] as num?)?.toInt() ?? 11,
      fromTeamXi:
          (json['from_team_xi'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      fromTeamKeeperId: json['from_team_keeper_id'] as String?,
      counteredStartTime: json['countered_start_time'] as String?,
      counteredVenue: json['countered_venue'] as String?,
      counteredFormatCode: json['countered_format_code'] as String?,
      counteredFormat: json['countered_format'] as Map<String, dynamic>?,
      counteredPlayersPerSide:
          (json['countered_players_per_side'] as num?)?.toInt(),
      status: json['status'] as String? ?? 'pending',
      decidedBy: json['decided_by'] as String?,
      decidedAt: json['decided_at'] as String?,
      decisionNote: json['decision_note'] as String?,
      decisionReason: json['decision_reason'] as String?,
      matchId: json['match_id'] as String?,
      shareCode: json['share_code'] as String?,
      codeExpiresAt: json['code_expires_at'] as String?,
      proposalExpiresAt: json['proposal_expires_at'] as String?,
      counterExpiresAt: json['counter_expires_at'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );

Map<String, dynamic> _$MatchRequestDtoToJson(_MatchRequestDto instance) =>
    <String, dynamic>{
      'request_id': instance.requestId,
      'from_team_id': instance.fromTeamId,
      'to_team_id': instance.toTeamId,
      'requested_by': instance.requestedBy,
      'proposed_start_time': instance.proposedStartTime,
      'proposed_venue': instance.proposedVenue,
      'proposed_format_code': instance.proposedFormatCode,
      'proposed_format': instance.proposedFormat,
      'message': instance.message,
      'players_per_side': instance.playersPerSide,
      'from_team_xi': instance.fromTeamXi,
      'from_team_keeper_id': instance.fromTeamKeeperId,
      'countered_start_time': instance.counteredStartTime,
      'countered_venue': instance.counteredVenue,
      'countered_format_code': instance.counteredFormatCode,
      'countered_format': instance.counteredFormat,
      'countered_players_per_side': instance.counteredPlayersPerSide,
      'status': instance.status,
      'decided_by': instance.decidedBy,
      'decided_at': instance.decidedAt,
      'decision_note': instance.decisionNote,
      'decision_reason': instance.decisionReason,
      'match_id': instance.matchId,
      'share_code': instance.shareCode,
      'code_expires_at': instance.codeExpiresAt,
      'proposal_expires_at': instance.proposalExpiresAt,
      'counter_expires_at': instance.counterExpiresAt,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };
